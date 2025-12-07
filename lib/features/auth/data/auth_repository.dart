import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:win33/core/models/login_response.dart';
import 'package:win33/core/network/dio_client.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/core/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:win33/features/auth/data/model/register_response.dart';

Future<String> ensureDeviceId() async {
  var id = await AppPrefs.getDeviceId();
  if (id == null) {
    id = const Uuid().v4();
    await AppPrefs.saveDeviceId(id);
  }
  return id;
}

class AuthRepository {
  final _client = DioClient.dio;

  // ======================================
  // LOGIN API
  // ======================================
  Future<LoginResponse> login({
    required String phone,
    required String password,
  }) async {
    final deviceId = await ensureDeviceId();
    final deviceInfo = DeviceInfoPlugin();
    String userAgent = "Win33-Mobile";

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      userAgent = "Android; ${info.model}; SDK ${info.version.sdkInt}";
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      userAgent = "iOS; ${info.utsname.machine}; ${info.systemVersion}";
    }

    final response = await _client.post(
      '/auth/login',
      data: {
        "phone": phone,
        "password": password,
        "deviceId": deviceId,
        "userAgent": userAgent,
      },
      options: Options(
        headers: {"x-device-id": deviceId, "User-Agent": userAgent},
      ),
    );

    final data = response.data;

    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];

    await AppPrefs.saveTokens(access: accessToken, refresh: refreshToken);

    final serverDeviceId = data['deviceId'];
    if (serverDeviceId != null) {
      await AppPrefs.saveDeviceId(serverDeviceId.toString());
    }

    final user = UserModel.fromJson(data['user']);
    await AppPrefs.saveUserJson(user.toJson());

    return LoginResponse(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  // ======================================
  // REGISTER API
  // ======================================
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    String? dob,
    String? gender,
    required String password,
  }) async {
    final response = await _client.post(
      "/auth/register",
      data: {
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "email": email,
        "dob": dob,
        "gender": gender,
        "password": password,
      },
    );

    return RegisterResponse.fromJson(response.data);
  }

  // ======================================
  // VERIFY OTP API
  // ======================================
  Future<bool> verifyOtp({required String userId, required String otp}) async {
    final res = await _client.post(
      "/auth/verify",
      data: {"userId": userId, "otp": otp},
    );

    final msg = res.data["message"]?.toString().toLowerCase() ?? "";

    // Accept ANY message that contains "verified"
    return msg.contains("verified");
  }

  // ======================================
  // FORGOT PASSWORD - SEND OTP
  // ======================================
  Future<bool> forgotPassword(String phone) async {
    final res = await _client.post(
      "/auth/forgot-password",
      data: {"phone": phone},
    );

    final msg = res.data["message"]?.toString().toLowerCase() ?? "";
    return msg.contains("otp");
  }

  // ======================================
  // VERIFY FORGOT OTP
  // RETURNS resetToken
  // ======================================
  Future<String> verifyForgotOtp({
    required String phone,
    required String otp,
  }) async {
    final res = await _client.post(
      "/auth/forgot-password/verify",
      data: {"phone": phone, "otp": otp},
    );

    return res.data["resetToken"]; 
  }

  // ======================================
  // RESET PASSWORD
  // ======================================
  Future<bool> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await _client.post(
      "/auth/reset-password",
      data: {"resetToken": resetToken, "newPassword": newPassword},
    );

    final msg = res.data["message"]?.toString().toLowerCase() ?? "";
    return msg.contains("success");
  }

  // ======================================
  // LOGOUT
  // ======================================
  Future<void> logout() async {
    try {
      final refreshToken = await AppPrefs.getRefreshToken();
      if (refreshToken != null) {
        await _client.post(
          "/auth/logout",
          data: {"refreshToken": refreshToken},
        );
      }
    } catch (_) {}

    await AppPrefs.clearUserData();
  }
}

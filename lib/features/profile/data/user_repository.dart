import 'package:win33/core/models/user_model.dart';
import 'package:win33/core/network/dio_client.dart';

class DeviceModel {
  final String deviceId;
  final String name;
  final String? ip;
  final DateTime? lastSeen;
  final bool isCurrent;

  DeviceModel({
    required this.deviceId,
    required this.name,
    this.ip,
    this.lastSeen,
    this.isCurrent = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['deviceId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ??
          json['deviceName'] ??
          json['userAgent'] ??
          'Unknown device',
      ip: json['ip'] ?? json['ipAddress'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      isCurrent: json['current'] == true ||
          json['isCurrent'] == true ||
          json['is_current'] == true,
    );
  }
}

class UserRepository {
  final _client = DioClient.dio;

  // Helper to handle responses where the user might be nested in data
  dynamic _unwrapResponseData(dynamic resData) {
    if (resData is Map && resData.containsKey('data')) {
      return resData['data'];
    }
    return resData;
  }

  Future<UserModel> getMyProfile() async {
    final res = await _client.get('/user/me');
    final body = _unwrapResponseData(res.data);
    if (body is Map<String, dynamic>) {
      return UserModel.fromJson(body);
    }
    throw Exception("Invalid profile response");
  }

  Future<UserModel> updateMyProfile(Map<String, dynamic> dto) async {
    final res = await _client.patch('/user/me', data: dto);
    final body = _unwrapResponseData(res.data);
    if (body is Map<String, dynamic>) {
      return UserModel.fromJson(body);
    }
    throw Exception("Invalid update profile response");
  }

  // Devices
  Future<List<DeviceModel>> getDevices() async {
    final res = await _client.get('/auth/devices');
    final body = _unwrapResponseData(res.data);
    if (body is List) {
      return body
          .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> revokeDevice(String deviceId) async {
    await _client.delete('/auth/devices/$deviceId');
  }
}

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:win33/core/network/app_token_manager.dart';
import 'package:win33/core/network/token_store.dart';

class DioClient {
  // ------------------------------------------------------------
  // BASE URL
  // ------------------------------------------------------------
  static const String _baseUrl =
      "https://server.lotto.redefyne.in/api";

  // ------------------------------------------------------------
  // MAIN DIO INSTANCE (WITH INTERCEPTORS)
  // ------------------------------------------------------------
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: "application/json",
    ),
  );

  // ------------------------------------------------------------
  // REFRESH-ONLY DIO (NO INTERCEPTORS)
  // ------------------------------------------------------------
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: "application/json",
    ),
  );

  // ------------------------------------------------------------
  // IN-MEMORY TOKENS
  // ------------------------------------------------------------
  static String? _accessToken;
  static String? _refreshToken;

  static Completer<void>? _refreshCompleter;

  // ------------------------------------------------------------
  // INITIALIZE (CALL BEFORE runApp)
  // ------------------------------------------------------------
  static Future<void> initialize() async {
    await AppTokenManager.instance.load();

    _accessToken = AppTokenManager.instance.tokens.accessToken;
    _refreshToken = AppTokenManager.instance.tokens.refreshToken;

    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null && _accessToken!.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $_accessToken";
          }

          return handler.next(options);
        },

        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;

          if (status == 401 && !_isRefresh(path)) {
            return _handle401(error, handler);
          }

          return handler.next(error);
        },
      ),
    );

    // Optional: enable logs in debug only
    // dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  // ------------------------------------------------------------
  // UPDATE TOKENS AFTER LOGIN
  // ------------------------------------------------------------
  static void updateTokens({
    required String access,
    required String refresh,
  }) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  // ------------------------------------------------------------
  // HANDLE 401 (TOKEN EXPIRED)
  // ------------------------------------------------------------
  static Future<void> _handle401(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return _retry(err.requestOptions, handler);
    }

    _refreshCompleter = Completer<void>();

    try {
      await _refreshTokens();
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      await AppTokenManager.instance.clear();
      return handler.next(err);
    } finally {
      _refreshCompleter = null;
    }

    return _retry(err.requestOptions, handler);
  }

  // ------------------------------------------------------------
  // REFRESH TOKENS (NO INTERCEPTORS)
  // ------------------------------------------------------------
  static Future<void> _refreshTokens() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw "No refresh token available";
    }

    final res = await _refreshDio.post(
      "/auth/refresh",
      data: {"refreshToken": _refreshToken},
      options: Options(
        headers: {
          "Authorization": "",
          "Content-Type": "application/json",
        },
      ),
    );

    final newAccess = res.data["accessToken"];
    final newRefresh = res.data["refreshToken"];

    _accessToken = newAccess;
    _refreshToken = newRefresh;

    await AppTokenManager.instance.save(
      TokenStore(
        accessToken: newAccess,
        refreshToken: newRefresh,
      ),
    );
  }

  // ------------------------------------------------------------
  // RETRY ORIGINAL REQUEST
  // ------------------------------------------------------------
  static Future<void> _retry(
    RequestOptions request,
    ErrorInterceptorHandler handler,
  ) async {
    final response = await dio.requestUri(
      request.uri,
      data: request.data,
      options: Options(
        method: request.method,
        headers: {
          ...request.headers,
          "Authorization": "Bearer $_accessToken",
        },
      ),
    );

    handler.resolve(response);
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  static bool _isRefresh(String path) =>
      path.contains("/auth/refresh");
}

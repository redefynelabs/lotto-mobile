import 'package:dio/dio.dart';
import 'package:dio_refresh/dio_refresh.dart';
import 'token_manager.dart';

class DioClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://server.lotto.redefyne.in/api",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: "application/json",
    ),
  );

  static Future<void> initialize() async {
  // Ensure tokens are loaded
  await AppTokenManager.instance.loadFromPrefs();

  // DEBUG: Print tokens to confirm they are loaded
  print("Access Token Loaded: ${AppTokenManager.instance.tokenManager.tokenStore?.accessToken != null}");
  print("Refresh Token: ${AppTokenManager.instance.tokenManager.tokenStore?.refreshToken}");

  dio.interceptors.clear();

  dio.interceptors.add(
    DioRefreshInterceptor(
      tokenManager: AppTokenManager.instance.tokenManager,

      authHeader: (tokenStore) {
        final token = tokenStore.accessToken;
        if (token == null || token.isEmpty) {
          print("No access token available for request");
          return {};
        }
        return {"Authorization": "Bearer $token"};
      },

      shouldRefresh: (response) {
        final should = response?.statusCode == 401 || response?.statusCode == 403;
        if (should) print("401/403 detected → triggering refresh");
        return should;
      },

      onRefresh: (client, tokenStore) async {
        print("Attempting token refresh...");
        try {
          final res = await client.post("/auth/refresh", data: {
            "refreshToken": tokenStore.refreshToken,
          });

          final newAccess = res.data["accessToken"] as String?;
          final newRefresh = res.data["refreshToken"] as String?;

          if (newAccess == null) throw "No access token in refresh response";

          // Save new tokens
          await AppTokenManager.instance.save(TokenStore(
            accessToken: newAccess,
            refreshToken: newRefresh,
          ));

          return TokenStore(accessToken: newAccess, refreshToken: newRefresh);
        } catch (e) {
          print("Token refresh failed: $e");
          // Force logout on refresh failure
          await AppTokenManager.instance.clear();
          rethrow;
        }
      },

    ),
  );

  // Optional: Add global error interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) {
      print("Dio Error: ${error.response?.statusCode} ${error.requestOptions.path}");
      if (error.response?.statusCode == 401) {
        print("Unauthorized → will be handled by DioRefresh");
      }
      handler.next(error);
    },
  ));

  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    error: true,
  ));
}
}

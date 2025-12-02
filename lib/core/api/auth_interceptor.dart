import 'package:dio/dio.dart';
import 'token_store.dart';

class AuthInterceptor extends Interceptor {
  final TokenStore tokenStore;
  final Dio dio;

  AuthInterceptor(this.tokenStore, this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStore.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await tokenStore.refresh(dio);
        if (refreshed) {
          final req = err.requestOptions;
          req.headers['Authorization'] = 'Bearer ${tokenStore.accessToken}';
          final clone = await dio.fetch(req);
          return handler.resolve(clone);
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}

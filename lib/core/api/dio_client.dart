import 'package:dio/dio.dart';

class DioClient {
  final Dio dio;

  DioClient(String baseUrl, {List<Interceptor>? interceptors})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        ) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }
  }
}

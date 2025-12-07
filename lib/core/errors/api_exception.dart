import 'package:dio/dio.dart';

class ApiExceptions implements Exception {
  final String message;
  final int? statusCode;

  ApiExceptions(this.message, {this.statusCode});

  factory ApiExceptions.fromDio(DioException e) {
    // Case: Server responded with error (e.response != null)
    if (e.response != null) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      String msg = "Something went wrong";

      if (data is Map && data.containsKey("message")) {
        msg = data["message"]?.toString() ?? msg;
      } else if (data is String) {
        msg = data; // sometimes backend returns raw string
      }

      return ApiExceptions(msg, statusCode: status);
    }

    // Case: No response (network error, timeout, DNS, no internet)
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiExceptions("Connection timeout. Please try again.");

      case DioExceptionType.connectionError:
        return ApiExceptions("No Internet connection.");

      case DioExceptionType.badCertificate:
        return ApiExceptions("Bad certificate from server.");

      case DioExceptionType.cancel:
        return ApiExceptions("Request was cancelled.");

      default:
        // fallback: use e.error if available
        return ApiExceptions(
          e.error?.toString() ?? "Unexpected network error",
        );
    }
  }

  @override
  String toString() => message;
}

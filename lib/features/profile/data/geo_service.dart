import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeoService {
  final _dio = Dio();

  Future<String> getLocationFromIp(String ip) async {
    try {
      final res = await _dio.get("https://ipapi.co/$ip/json/");
      final data = res.data;

      final city = data["city"];
      final country = data["country_name"];

      if (city != null && country != null) {
        return "$city, $country";
      }
      if (country != null) return country;
    } catch (_) {}

    return "Unknown Location";
  }
}

final geoServiceProvider = Provider((ref) => GeoService());

final deviceLocationProvider =
    FutureProvider.family<String, String>((ref, ip) async {
  return ref.read(geoServiceProvider).getLocationFromIp(ip);
});


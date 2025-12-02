import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class TokenStore {
  String? accessToken;
  String? refreshToken;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('accessToken');
    refreshToken = prefs.getString('refreshToken');
  }

  Future<void> save(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', access);
    await prefs.setString('refreshToken', refresh);
    accessToken = access;
    refreshToken = refresh;
  }

  Future<bool> refresh(Dio dio) async {
    if (refreshToken == null) return false;

    final res = await dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });

    if (res.statusCode == 200) {
      save(res.data['accessToken'], res.data['refreshToken']);
      return true;
    }
    return false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    accessToken = null;
    refreshToken = null;
  }
}

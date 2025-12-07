import 'package:dio_refresh/dio_refresh.dart';
import 'package:win33/core/storage/app_prefs.dart';

class AppTokenManager {
  static final instance = AppTokenManager._internal();

  final TokenManager tokenManager = TokenManager.instance;

  AppTokenManager._internal();

  Future<void> loadFromPrefs() async {
    final access = await AppPrefs.getAccessToken();
    final refresh = await AppPrefs.getRefreshToken();

    tokenManager.setToken(
      TokenStore(
        accessToken: access,
        refreshToken: refresh,
      ),
    );
  }

  Future<void> save(TokenStore token) async {
    await AppPrefs.saveTokens(
      access: token.accessToken!,
      refresh: token.refreshToken!,
    );
  }

  Future<void> clear() async {
    await AppPrefs.clearUserData();

    // 👇 Correct way to clear token in dio_refresh
    tokenManager.setToken(
      TokenStore(
        accessToken: null,
        refreshToken: null,
      ),
    );
  }
}

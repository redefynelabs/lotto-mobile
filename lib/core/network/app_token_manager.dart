import 'package:win33/core/storage/secure_store.dart';
import 'package:win33/core/network/token_store.dart';

class AppTokenManager {
  static final instance = AppTokenManager._internal();

  TokenStore _tokens = const TokenStore();

  AppTokenManager._internal();

  TokenStore get tokens => _tokens;

  Future<void> load() async {
    final access = await SecureStore.read("accessToken");
    final refresh = await SecureStore.read("refreshToken");

    _tokens = TokenStore(
      accessToken: access,
      refreshToken: refresh,
    );

    // print("🔐 SecureStorage Loaded Tokens → $_tokens");
  }

  Future<void> save(TokenStore token) async {
    _tokens = token;

    if (token.accessToken != null) {
      await SecureStore.write("accessToken", token.accessToken!);
    }

    if (token.refreshToken != null) {
      await SecureStore.write("refreshToken", token.refreshToken!);
    }

    // print("💾 Tokens Saved To SecureStorage → $_tokens");
  }

  Future<void> clear() async {
    await SecureStore.delete("accessToken");
    await SecureStore.delete("refreshToken");
    _tokens = const TokenStore();
    // print("🧹 Tokens Cleared From SecureStorage");
  }
}

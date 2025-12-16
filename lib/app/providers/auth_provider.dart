import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:win33/features/auth/data/auth_repository.dart';
import 'package:win33/core/network/app_token_manager.dart';
import 'package:win33/core/network/token_store.dart';
import 'package:win33/core/network/dio_client.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/models/user_model.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isInitializing;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.isLoggedIn,
    this.isLoading = false,
    this.isInitializing = true,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isInitializing,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(AuthState(isLoggedIn: false)) {
    _loadUser();
  }

  final Ref ref;
  final repo = AuthRepository();

  Future<void> _loadUser() async {
    await AppTokenManager.instance.load();
    final tokens = AppTokenManager.instance.tokens;

    final userJson = await AppPrefs.getUserJson();

    if (tokens.hasBoth && userJson != null) {
      final user = UserModel.fromJson(userJson);
      ref.read(userProvider.notifier).setUser(user);

      state = state.copyWith(
        isLoggedIn: true,
        isInitializing: false,
        user: user,
      );

      ref.read(userProvider.notifier).loadUser(); // background sync
    } else {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> login(String phone, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final login = await repo.login(phone: phone, password: password);

      final user = login.user;

      await AppPrefs.saveUserJson(user.toJson());

      final tokens = TokenStore(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
      );

      await AppTokenManager.instance.save(tokens);

      DioClient.updateTokens(
        access: login.accessToken,
        refresh: login.refreshToken,
      );

      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: user,
      );

      ref.read(userProvider.notifier).setUser(user);
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletHistoryProvider);

      ref.read(userProvider.notifier).loadUser();
    } catch (e) {
      String msg = "Login failed";

      if (e is DioException) {
        msg = e.response?.data?["message"] ?? msg;
      }

      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<void> logout() async {
    await AppTokenManager.instance.clear();
    await AppPrefs.clearUserData();

    ref.read(userProvider.notifier).logout();

    state = AuthState(isLoggedIn: false, isInitializing: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

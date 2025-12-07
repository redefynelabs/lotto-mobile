import 'package:dio/dio.dart';
import 'package:dio_refresh/dio_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/models/user_model.dart';
import 'package:win33/core/network/token_manager.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/features/auth/data/auth_repository.dart';
import 'package:win33/features/profile/presentation/profile_page.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isInitializing;
  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;

  AuthState({
    required this.isLoggedIn,
    this.isInitializing = true,
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isInitializing,
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref)
    : super(AuthState(isLoggedIn: false, isInitializing: true)) {
    _loadUser();
  }

  final Ref ref;
  final repo = AuthRepository();

  Future<void> _loadUser() async {
    try {
      final token = await AppPrefs.getAccessToken();
      final userJson = await AppPrefs.getUserJson();

      if (token != null && token.isNotEmpty && userJson != null) {
        final user = UserModel.fromJson(userJson);
        state = state.copyWith(
          isLoggedIn: true,
          isInitializing: false,
          user: user,
          errorMessage: null,
        );

        // Ensure userProvider is immediately synced
        ref.read(userProvider.notifier).setUser(user);

        // Attempt to refresh latest profile in background
        ref.read(userProvider.notifier).loadUser();
      } else {
        state = state.copyWith(isInitializing: false);
      }
    } catch (e) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> login(String phone, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // API → returns LoginResponse (user + tokens)
      final login = await repo.login(phone: phone, password: password);
      final user = login.user;

      // ================================
      // 1️⃣ SAVE USER + TOKENS IMMEDIATELY
      // ================================
      await AppPrefs.saveUserJson(user.toJson());

      await AppPrefs.saveTokens(
        access: login.accessToken,
        refresh: login.refreshToken,
      );

      // ================================================
      // 2️⃣ UPDATE DioRefresh TokenManager immediately
      // ================================================
      AppTokenManager.instance.tokenManager.setToken(
        TokenStore(
          accessToken: login.accessToken,
          refreshToken: login.refreshToken,
        ),
      );

      // ==========================
      // 3️⃣ UPDATE AUTH STATE
      // ==========================
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        user: user,
        errorMessage: null,
        isInitializing: false,
      );

      // ================================
      // 4️⃣ SYNC USER PROVIDER INSTANTLY
      // ================================
      final userNotifier = ref.read(userProvider.notifier);
      userNotifier.setUser(user);

      // =========================================
      // 5️⃣ INVALIDATE TOKEN DEPENDENT PROVIDERS
      // =========================================
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletHistoryProvider);
      ref.invalidate(devicesProvider);

      // =============================
      // 6️⃣ REFRESH PROFILE IN BACKGROUND
      // =============================
      userNotifier.loadUser();
    } catch (e) {
      String message = "Login failed";

      if (e is DioException) {
        final data = e.response?.data;

        if (data is Map && data["message"] != null) {
          message = data["message"]; // backend message
        } else {
          message = e.message ?? message; // fallback
        }
      } else {
        message = e.toString();
      }

      state = state.copyWith(isLoading: false, errorMessage: message);
    }
  }

  Future<void> logout() async {
    try {
      await repo.logout();
    } catch (_) {}

    await AppPrefs.clearUserData();

    // reset user provider
    await ref.read(userProvider.notifier).logout();

    // reset auth state
    state = AuthState(
      isLoggedIn: false,
      isInitializing: false,
      isLoading: false,
      user: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

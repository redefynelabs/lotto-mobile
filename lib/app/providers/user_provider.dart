import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:win33/core/models/user_model.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/features/profile/data/user_repository.dart';
import 'package:win33/core/network/app_token_manager.dart';

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository repo;
  final Ref ref;

  UserNotifier(this.repo, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  // ================================================================
  // INIT — check secure tokens + restore cached user + sync from API
  // ================================================================
  Future<void> _init() async {
    final tokens = AppTokenManager.instance.tokens;

    // 🔥 No secure tokens → guest user
    if (!tokens.hasBoth) {
      state = const AsyncValue.data(null);
      return;
    }

    // Load cached user first (instant UI)
    final cachedJson = await AppPrefs.getUserJson();
    if (cachedJson != null) {
      try {
        final cachedUser = UserModel.fromJson(cachedJson);
        state = AsyncValue.data(cachedUser);
      } catch (_) {
        // Ignore corrupted cache
      }
    }

    // Fetch fresh user data
    await loadUser();
  }

  // ================================================================
  // SET USER (After login)
  // ================================================================
  void setUser(UserModel? user) {
    if (user == null) {
      state = const AsyncValue.data(null);
      AppPrefs.clearUserData();
      return;
    }

    state = AsyncValue.data(user);
    AppPrefs.saveUserJson(user.toJson());
  }

  // ================================================================
  // LOAD USER FROM API
  // ================================================================
  Future<void> loadUser() async {
    final prev = state;
    state = const AsyncValue.loading();

    try {
      final fresh = await repo.getMyProfile();
      await AppPrefs.saveUserJson(fresh.toJson());
      state = AsyncValue.data(fresh);
      return;
    } catch (e, st) {
      // If request fails because tokens are invalid → logout user
      final tokens = AppTokenManager.instance.tokens;
      if (!tokens.hasBoth) {
        await AppPrefs.clearUserData();
        state = const AsyncValue.data(null);
        return;
      }

      // Recover UI using cached or previous data
      state = prev;
    }
  }

  // ================================================================
  // UPDATE PROFILE
  // ================================================================
  Future<void> updateFullProfile({
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime dob,
  }) async {
    try {
      final updated = await repo.updateMyProfile({
        "firstName": firstName,
        "lastName": lastName,
        "gender": gender,
        "dob": dob.toIso8601String(),
      });

      await AppPrefs.saveUserJson(updated.toJson());
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ================================================================
  // LOGOUT
  // ================================================================
  Future<void> logout() async {
    await AppPrefs.clearUserData();
    state = const AsyncValue.data(null);
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(UserRepository(), ref);
});

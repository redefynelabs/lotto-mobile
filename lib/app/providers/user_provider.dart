import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:win33/core/models/user_model.dart';
import 'package:win33/core/storage/app_prefs.dart';
import 'package:win33/features/profile/data/user_repository.dart';

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository repo;
  final Ref ref;

  UserNotifier(this.repo, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final token = await AppPrefs.getAccessToken();

    // If no token → guest mode
    if (token == null || token.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    // Try to restore cached user first (fast UI)
    final cachedJson = await AppPrefs.getUserJson();
    if (cachedJson != null) {
      try {
        final cachedUser = UserModel.fromJson(cachedJson);
        state = AsyncValue.data(cachedUser);
      } catch (_) {
        // corrupted cache → ignore
      }
    }

    // Then fetch fresh data from server
    await loadUser();
  }

  /// Called by AuthNotifier after login or token restore
  void setUser(UserModel? user) {
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    state = AsyncValue.data(user);
    AppPrefs.saveUserJson(user.toJson());
  }

  /// Force refresh from server (used on pull-to-refresh, profile edit, etc.)
  Future<void> loadUser() async {
    final previous = state;
    state = AsyncValue.loading();

    try {
      final fresh = await repo.getMyProfile();
      await AppPrefs.saveUserJson(fresh.toJson());
      state = AsyncValue.data(fresh);
    } catch (e, st) {
      // restore previous data
      state = previous;
    }

    try {
      final freshUser = await repo.getMyProfile();
      await AppPrefs.saveUserJson(freshUser.toJson());
      state = AsyncValue.data(freshUser);
    } catch (e, st) {
      // Keep old data on failure → no flicker
      if (state is AsyncData<UserModel?>) {
        state = AsyncValue.data((state as AsyncData<UserModel?>).value);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

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

  Future<void> logout() async {
    await AppPrefs.clearUserData();
    state = const AsyncValue.data(null);
  }
}

// This is the correct way — no watching authProvider here!
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
      return UserNotifier(UserRepository(), ref);
    });

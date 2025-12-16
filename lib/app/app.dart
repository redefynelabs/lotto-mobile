import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:win33/app/presentation/main_wrapper.dart';
import 'package:win33/app/providers/auth_provider.dart';

import 'package:win33/core/theme/app_theme.dart';

import 'package:win33/features/auth/presentation/login_page.dart';
import 'package:win33/features/auth/presentation/unauthorized_page.dart';
import 'package:win33/features/onboarding/presentation/onboarding_page.dart';
import 'package:win33/features/home/presentation/home_page.dart';
import 'package:win33/features/profile/presentation/profile_page.dart';
import 'package:win33/features/bid/presentation/bid_page.dart';
import 'package:win33/features/results/presentation/resuts_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Win33',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthMiddleware(),

      routes: {
        '/login': (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/unauthorized': (_) => const UnauthorizedPage(),
        '/home': (_) => const HomePage(),
        '/profile': (_) => const ProfilePage(),
        '/bid': (_) => const BidPage(),
        '/results': (_) => const ResultsPage(),
      },
    );
  }
}

class AuthMiddleware extends ConsumerWidget {
  const AuthMiddleware({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // ⏳ 1. App still loading tokens
    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🟡 2. User NOT logged in → onboarding
    if (!auth.isLoggedIn) {
      return const OnboardingPage();
    }

    // 🔴 3. Logged in but user record not verified
    if (auth.user?.isApproved == false) {
      return const UnauthorizedPage();
    }

    // 🟢 4. Fully logged in
    return MainWrapper(isLoggedIn: true);
  }
}


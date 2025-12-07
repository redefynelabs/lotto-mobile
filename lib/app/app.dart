import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/presentation/main_wrapper.dart';
import 'package:win33/app/providers/auth_provider.dart';
import 'package:win33/core/theme/app_theme.dart';
import 'package:win33/features/auth/presentation/login_page.dart';
import 'package:win33/features/home/presentation/home_page.dart';
import 'package:win33/features/onboarding/presentation/onboarding_page.dart';

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
        '/home': (_) => const HomePage(),
      },
    );
  }
}
class AuthMiddleware extends ConsumerWidget {
  const AuthMiddleware({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 Not logged in → Show onboarding ONLY
    if (!authState.isLoggedIn) {
      return const OnboardingPage();
    }

    // 🔥 Logged in → Full access
    return MainWrapper(isLoggedIn: true);
  }
}

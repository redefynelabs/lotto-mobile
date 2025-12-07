import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/auth/presentation/login_page.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle,
                size: 100, color: Colors.green.shade600),

            const SizedBox(height: 20),

            const Text("Password Updated!",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            const Text(
              "You can now log in with your new password.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 12),
              ),
              child:
                  const Text("Back to Login", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

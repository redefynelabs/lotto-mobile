import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/auth_banner.dart';
import 'package:win33/features/auth/data/auth_repository.dart';
import 'package:win33/features/auth/presentation/otp_page.dart';
import 'package:win33/features/auth/presentation/password_reset_success.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int step = 1;

  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String resetToken = "";

  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AuthBanner(height: 240),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // MAIN CONTENT SWITCHER
  // ===========================
  Widget _buildContent() {
    switch (step) {
      case 1:
        return _stepPhone();
      case 3:
        return _stepNewPassword();
      default:
        return _stepPhone();
    }
  }

  // ===========================
  // STEP 1 — ENTER PHONE
  // ===========================
  Widget _stepPhone() {
    return Column(
      key: const ValueKey("step1"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Forgot Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),
        const Text(
          "Enter your registered phone number.",
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 24),

        const Text("Phone Number", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 6),

        _inputField(
          hint: "Enter your phone number",
          controller: phoneCtrl,
          keyboard: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),

        const Spacer(),

        _primaryButton(
          label: "Send OTP",
          onPressed: () async {
            final phone = phoneCtrl.text.trim();

            if (phone.length != 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Enter valid phone")),
              );
              return;
            }

            final repo = AuthRepository();

            final ok = await repo.forgotPassword(phone);

            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to send OTP")),
              );
              return;
            }

            // PUSH OTP PAGE FOR FORGOT MODE
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpPage(
                  mode: "forgot",
                  phone: phone,
                  userId: "", // not used for forgot
                ),
              ),
            );

            if (result != null && result is String) {
              // result = resetToken
              resetToken = result;
              setState(() => step = 3);
            }
          },
        ),
      ],
    );
  }

  // ===========================
  // STEP 3 — SET NEW PASSWORD
  // ===========================
  Widget _stepNewPassword() {
    return Column(
      key: const ValueKey("step3"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Set New Password",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),

        const Text("New Password"),
        const SizedBox(height: 6),
        _passwordInput(
          controller: passCtrl,
          show: showPassword,
          onToggle: () => setState(() => showPassword = !showPassword),
        ),

        const SizedBox(height: 16),

        const Text("Confirm Password"),
        const SizedBox(height: 6),
        _passwordInput(
          controller: confirmCtrl,
          show: showConfirmPassword,
          onToggle: () =>
              setState(() => showConfirmPassword = !showConfirmPassword),
        ),

        const Spacer(),

        _primaryButton(
          label: "Update Password",
          onPressed: () async {
            if (passCtrl.text != confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Passwords do not match")),
              );
              return;
            }

            if (passCtrl.text.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password too short")),
              );
              return;
            }

            final repo = AuthRepository();
            final ok = await repo.resetPassword(
              resetToken: resetToken,
              newPassword: passCtrl.text.trim(),
            );

            if (ok) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PasswordResetSuccessScreen(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to reset password")),
              );
            }
          },
        ),
      ],
    );
  }

  // ===========================
  // COMMON INPUT FIELD
  // ===========================
  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightgray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ===========================
  // PASSWORD FIELD
  // ===========================
  Widget _passwordInput({
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightgray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility : Icons.visibility_off),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  // ===========================
  // PRIMARY BUTTON
  // ===========================
  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

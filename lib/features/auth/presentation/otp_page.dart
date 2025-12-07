import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/auth_banner.dart';
import 'package:win33/features/auth/data/auth_repository.dart';
import 'package:win33/features/auth/presentation/password_reset_success.dart';
import 'signup_approval_page.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String mode; // "signup" | "forgot"
  final String userId;

  const OtpPage({
    super.key,
    required this.phone,
    required this.mode,
    required this.userId,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final ctrls = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      nodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthBanner(height: 220),

            const SizedBox(height: 20),

            const Text(
              "Verify OTP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "OTP sent to ${widget.phone}",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : _verifyOtp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // OTP Input Box
  // -------------------------------
  Widget _otpBox(int i) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: ctrls[i],
        focusNode: nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.lightgray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) {
            nodes[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            nodes[i - 1].requestFocus();
          }
        },
      ),
    );
  }

  // -------------------------------
  // Verify OTP API Integration
  // -------------------------------
  Future<void> _verifyOtp() async {
    final otp = ctrls.map((e) => e.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid 6-digit OTP")));
      return;
    }

    setState(() => isLoading = true);

    final repo = AuthRepository();

    try {
      if (widget.mode == "signup") {
        // existing logic
        final ok = await repo.verifyOtp(userId: widget.userId, otp: otp);

        if (!ok) throw "Invalid OTP";

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupApprovalPage()),
        );
      } else {
        // ⭐ FORGOT PASSWORD → VERIFY OTP AND RETURN resetToken
        final token = await repo.verifyForgotOtp(phone: widget.phone, otp: otp);

        Navigator.pop(context, token); // return resetToken
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("OTP verification failed: $e")));
    }

    setState(() => isLoading = false);
  }
}

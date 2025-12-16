import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/auth_banner.dart';
import 'package:win33/features/auth/data/auth_repository.dart';
import 'package:win33/features/auth/presentation/otp_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController();

  String? gender; // Stored value → MALE / FEMALE / OTHER
  String? _dobUtc;

  final genderOptions = {"MALE": "Male", "FEMALE": "Female", "OTHER": "Other"};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // const AuthBanner(height: 240),
          const SizedBox(height: 60),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: "Coolvetica",
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Sign up to get started",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  _label("First Name"),
                  _inputField(
                    hint: "Enter first name",
                    controller: firstNameCtrl,
                  ),
                  const SizedBox(height: 16),

                  _label("Last Name"),
                  _inputField(
                    hint: "Enter last name",
                    controller: lastNameCtrl,
                  ),
                  const SizedBox(height: 16),

                  _label("Phone Number"),
                  _inputField(
                    hint: "Enter phone number",
                    controller: phoneCtrl,
                    keyboard: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 16),

                  _label("Email Address"),
                  _inputField(
                    hint: "Enter email address",
                    controller: emailCtrl,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _label("Date of Birth"),
                  GestureDetector(
                    onTap: _pickDOB,
                    child: AbsorbPointer(
                      child: _inputField(
                        hint: "Select date of birth",
                        controller: dobCtrl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _label("Gender"),
                  _genderDropdown(),
                  const SizedBox(height: 30),

                  _primaryButton(
                    label: "Continue",
                    onPressed: () async {
                      if (!_valid()) return;

                      final repo = AuthRepository();
                      try {
                        final result = await repo.register(
                          firstName: firstNameCtrl.text,
                          lastName: lastNameCtrl.text,
                          phone: phoneCtrl.text,
                          email: emailCtrl.text,
                          dob: _dobUtc,
                          gender: gender, // MALE / FEMALE / OTHER
                          password: "123456", // Or ask user later
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtpPage(
                              mode: "signup",
                              phone: phoneCtrl.text.trim(),
                              userId: result.userId,
                            ),
                          ),
                        );
                      } catch (e) {
                        String errorMsg = "Signup failed";

                        if (e is DioException) {
                          final data = e.response?.data;

                          if (data is Map && data["message"] != null) {
                            errorMsg = data["message"]; // ⭐ Backend message
                          } else {
                            errorMsg = e.message ?? errorMsg; // fallback
                          }
                        } else {
                          errorMsg = e.toString();
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(errorMsg)));
                      }
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // LABEL (For all input fields)
  // -----------------------------
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: "Coolvetica",
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // -----------------------------
  // REUSABLE INPUT FIELD (Match UI)
  // -----------------------------
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
          hintStyle: const TextStyle(
            color: Colors.black38,
            fontFamily: "Coolvetica",
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // GENDER DROPDOWN (Styled like input)
  // -----------------------------
  Widget _genderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightgray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: gender,
          hint: const Text(
            "Select gender",
            style: TextStyle(color: Colors.black38, fontFamily: "Coolvetica"),
          ),
          isExpanded: true,
          items: genderOptions.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key, // MALE / FEMALE / OTHER
              child: Text(
                entry.value,
                style: TextStyle(fontFamily: "Coolvetica"),
              ), // Male / Female / Other
            );
          }).toList(),
          onChanged: (value) {
            setState(() => gender = value);
          },
        ),
      ),
    );
  }

  // -----------------------------
  // DOB PICKER
  // -----------------------------
  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      // For UI display
      final display = "${picked.year}-${picked.month}-${picked.day}";
      dobCtrl.text = display;

      // Save UTC conversion separately
      _dobUtc = DateTime.utc(
        picked.year,
        picked.month,
        picked.day,
      ).toIso8601String();
    }
  }

  // -----------------------------
  // VALIDATION
  // -----------------------------
  bool _valid() {
    if (firstNameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        phoneCtrl.text.length != 10 ||
        emailCtrl.text.isEmpty ||
        dobCtrl.text.isEmpty ||
        gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly")),
      );
      return false;
    }
    return true;
  }

  // -----------------------------
  // BUTTON
  // -----------------------------
  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: "Coolvetica",
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

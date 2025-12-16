import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:win33/app/providers/user_provider.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/core/widgets/common/app_toast.dart';

class ProfileEditForm extends ConsumerStatefulWidget {
  const ProfileEditForm({super.key});

  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  late TextEditingController firstCtrl;
  late TextEditingController lastCtrl;

  String selectedGender = "Male";
  DateTime selectedDob = DateTime(2000, 1, 1);

  @override
  void initState() {
    super.initState();
    firstCtrl = TextEditingController();
    lastCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider).value;

      if (user != null) {
        setState(() {
          firstCtrl.text = user.firstName;
          lastCtrl.text = user.lastName;
          selectedGender = _normalizeGender(user.gender);
          selectedDob = user.dob?.toLocal() ?? DateTime(2000, 1, 1);
        });
      }
    });
  }

  String _normalizeGender(String? g) {
    switch (g?.toUpperCase()) {
      case "MALE":
        return "Male";
      case "FEMALE":
        return "Female";
      case "OTHER":
        return "Other";
      default:
        return "Male";
    }
  }

  String _toBackendGender(String g) => g.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _textInput("First Name", firstCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _textInput("Last Name", lastCtrl)),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _genderDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _dobSelector(context)),
          ],
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              // 1️⃣ Convert selected date → UTC midnight
              final utcDob = DateTime.utc(
                selectedDob.year,
                selectedDob.month,
                selectedDob.day,
              );

              final notifier = ref.read(userProvider.notifier);

              await notifier.updateFullProfile(
                firstName: firstCtrl.text.trim(),
                lastName: lastCtrl.text.trim(),
                gender: _toBackendGender(selectedGender),
                dob: utcDob,
              );

              // 2️⃣ Refresh user globally
              ref.invalidate(userProvider);

              if (!mounted) return;

              // 3️⃣ Toast
              AppToast.show(context, message: "Profile updated successfully!");
            },
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontFamily: "Coolvetica"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: "Coolvetica")),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightgray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: ctrl,
            style: TextStyle(fontFamily: "Coolvetica"),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender", style: TextStyle(fontFamily: "Coolvetica")),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: _pickerBox(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              style: TextStyle(fontFamily: "Coolvetica", color: Colors.black),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (v) {
                if (v != null) setState(() => selectedGender = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _dobSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DOB", style: TextStyle(fontFamily: "Coolvetica")),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _openCalendar(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: _pickerBox(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat("dd-MM-yyyy").format(selectedDob),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SvgPicture.asset(
                  'assets/icons/calendar.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openCalendar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CalendarDatePicker(
                initialDate: selectedDob,
                firstDate: DateTime(1960),
                lastDate: DateTime.now(),
                onDateChanged: (d) => setState(() => selectedDob = d),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Select"),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _pickerBox() {
    return BoxDecoration(
      color: AppColors.lightgray,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class LotteryToggle extends StatefulWidget {
  const LotteryToggle({Key? key}) : super(key: key);

  @override
  State<LotteryToggle> createState() => _LotteryToggleState();
}

class _LotteryToggleState extends State<LotteryToggle> {
  int _selectedIndex = 0; // 0 = Lucky Draw, 1 = Jackpot
  DateTime? selectedDate;

  final List<String> tabs = ["Lucky Draw", "Jackpot"];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = Color(0xFFE30613); // adjust if you have AppColors.primary

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Toggle Pill
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: primaryRed, width: 2),
          ),
          child: Row(
            children: List.generate(tabs.length, (index) {
              bool isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(width: 20),

        // Date Button
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: primaryRed,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedDate == null
                      ? "Today"
                      : DateFormat('MMM dd').format(selectedDate!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  "assets/icons/calendar.svg", // your calendar SVG
                  color: Colors.white,
                  width: 18,
                  height: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
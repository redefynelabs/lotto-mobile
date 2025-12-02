import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool isJackpot;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.subLabel,
    required this.icon,
    this.isJackpot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isJackpot ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isJackpot ? null : Border.all(color: AppColors.thunderbird200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: isJackpot ? Colors.yellow : AppColors.thunderbird400),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isJackpot ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(subLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isJackpot ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

class InstructionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const InstructionCard({super.key, required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppColors.primary, child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
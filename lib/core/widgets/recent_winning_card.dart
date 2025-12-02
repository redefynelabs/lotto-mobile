import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

class RecentWinningCard extends StatelessWidget {
  final String date;
  final String time;
  final String number;

  const RecentWinningCard({
    super.key,
    required this.date,
    required this.time,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(time, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Text(
              number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
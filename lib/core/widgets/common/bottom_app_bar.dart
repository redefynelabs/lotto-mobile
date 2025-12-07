import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:win33/core/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            index: 0,
            label: "Home",
            icon: "assets/icons/home.svg",
            activeIcon: "assets/icons/bold/home.svg",
          ),
          _navItem(
            index: 1,
            label: "Bid",
            icon: "assets/icons/coin.svg",
            activeIcon: "assets/icons/bold/coin.svg",
          ),
          _navItem(
            index: 2,
            label: "Results",
            icon: "assets/icons/result.svg",
            activeIcon: "assets/icons/bold/result.svg",
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required int index,
    required String label,
    required String icon,
    required String activeIcon,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            isActive ? activeIcon : icon,
            height: 28,
            width: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

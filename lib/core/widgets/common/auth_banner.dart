import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

class AuthBanner extends StatelessWidget {
  final double height;
  final String image;

  const AuthBanner({
    super.key,
    this.height = 280,
    this.image = "assets/images/ball_poster.png",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Image.asset(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

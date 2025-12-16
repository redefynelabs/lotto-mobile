import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

class Footer extends StatelessWidget {
  final double opacity;
  final EdgeInsetsGeometry padding;

  const Footer({
    super.key,
    this.opacity = 0.25,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // 🔥 FORCE LEFT
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 🔥 LEFT
          children: [
            Text(
              "Luck favors",
              style: TextStyle(
                fontFamily: "Coolvetica",
                fontSize: 68,
                height: 1.05,
                letterSpacing: -0.5,
                fontWeight: FontWeight.w400,
                color: Colors.black.withOpacity(opacity),
              ),
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: "Coolvetica",
                  fontSize: 60,
                  height: 1.05,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(opacity),
                ),
                children: [
                  const TextSpan(text: "the "),
                  TextSpan(
                    text: "bold.",
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(opacity),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

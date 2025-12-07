import 'package:flutter/material.dart';

class FadeWrapper extends StatelessWidget {
  final Widget child;
  const FadeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}

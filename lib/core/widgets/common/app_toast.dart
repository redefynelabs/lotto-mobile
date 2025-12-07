import 'package:flutter/material.dart';
import 'dart:async';

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove old toast
    _remove();

    final overlay = Overlay.of(context)!;

    _entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 80,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    // Remove after duration
    _timer = Timer(duration, () => _remove());
  }

  static void _remove() {
    _timer?.cancel();
    _timer = null;

    _entry?.remove();
    _entry = null;
  }
}

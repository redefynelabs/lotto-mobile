import 'package:intl/intl.dart';

class ResultModel {
  final String slotId;
  final String uniqueSlotId;
  final String type; // "LD" | "JP"

  // Raw strings from backend (show these directly)
  final String dateStr; // "2025-12-07"
  final String timeStr; // "4:00PM"

  // For sorting only (constructed from dateStr + timeStr)
  final DateTime slotTime;

  final bool isVisible;
  final int? winningNumber;
  final List<int>? winningCombo;

  ResultModel({
    required this.slotId,
    required this.uniqueSlotId,
    required this.type,
    required this.dateStr,
    required this.timeStr,
    required this.slotTime,
    required this.isVisible,
    required this.winningNumber,
    required this.winningCombo,
  });
  
  factory ResultModel.empty() {
  return ResultModel(
    slotId: '',
    uniqueSlotId: '',
    type: '',
    dateStr: '',
    timeStr: '',
    slotTime: DateTime.now(),
    isVisible: false,
    winningNumber: null,
    winningCombo: null,
  );
}


  factory ResultModel.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String? ?? '';
    final time = json['time'] as String? ?? '';

    // Parse 12-hour time for sorting only (e.g. "4:00PM" -> hour/minute)
    DateTime slotTime;
    try {
      final parsedTime = DateFormat('h:mma').parse(time);
      final hour = parsedTime.hour;
      final minute = parsedTime.minute;

      // parse date parts
      final parts = date.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 1970;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        slotTime = DateTime(y, m, d, hour, minute);
      } else {
        // fallback to now
        slotTime = DateTime.now();
      }
    } catch (e) {
      // fallback in case backend format is unexpected
      try {
        slotTime = DateTime.parse(date);
      } catch (_) {
        slotTime = DateTime.now();
      }
    }

    final raw = json['winningNumber'];
    int? single;
    List<int>? combo;

    if (raw != null) {
      if (raw is int) {
        single = raw;
      } else {
        single = int.tryParse(raw.toString());
      }
    }

    if (single == null && raw != null) {
      final s = raw.toString();
      if (s.contains('-')) {
        combo = s
            .split('-')
            .map((e) => int.tryParse(e.trim()))
            .where((e) => e != null)
            .map((e) => e!)
            .toList();
      }
    }

    // Also support the backend sending winningCombo array directly
    if (combo == null && json['winningCombo'] != null) {
      try {
        final wc = (json['winningCombo'] as List).map((e) {
          if (e is int) return e;
          return int.tryParse(e.toString()) ?? 0;
        }).toList();
        combo = wc;
      } catch (_) {
        // ignore
      }
    }

    return ResultModel(
      slotId: json['slotId'] as String? ?? '',
      uniqueSlotId: json['uniqueSlotId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      dateStr: date,
      timeStr: time,
      slotTime: slotTime,
      isVisible: json['isVisible'] as bool? ?? true,
      winningNumber: single,
      winningCombo: combo,
    );
  }
}

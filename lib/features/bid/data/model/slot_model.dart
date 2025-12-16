class SlotModel {
  final String id;
  final String uniqueSlotId;
  final String type; // "LD" or "JP"
  final String status; // "OPEN"/"CLOSED"/"COMPLETED"
  final String slotTime; // ISO string (UTC)
  final String windowCloseAt; // ISO string (UTC)
  final Map<String, dynamic> settingsJson;
  final Map<String, dynamic>? drawResult;
  final String? slotTimeMYT;
  final String? slotTimeFormatted;

  SlotModel({
    required this.id,
    required this.uniqueSlotId,
    required this.type,
    required this.status,
    required this.slotTime,
    required this.windowCloseAt,
    required this.settingsJson,
    this.drawResult,
    this.slotTimeMYT,
    this.slotTimeFormatted,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id']?.toString() ?? '',
      uniqueSlotId:
          json['uniqueSlotId']?.toString() ??
          json['uniqueSlotId']?.toString() ??
          '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      slotTime: json['slotTime'] ?? '',
      windowCloseAt: json['windowCloseAt'] ?? '',
      settingsJson: (json['settingsJson'] is Map)
          ? Map<String, dynamic>.from(json['settingsJson'])
          : {},
      drawResult: json['drawResult'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['drawResult'])
          : null,
      slotTimeMYT: json['slotTimeMYT']?.toString(),
      slotTimeFormatted: json['slotTimeFormatted']?.toString(),
    );
  }
}

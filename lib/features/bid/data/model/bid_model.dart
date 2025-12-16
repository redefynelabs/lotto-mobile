import 'slot_model.dart';

class BidModel {
  final String id;
  final String? userId;
  final String? slotId;
  final String? uniqueBidId;
  final String customerName;
  final String? customerPhone;
  final int? number;
  final int? count;
  final List<int>? jpNumbers;
  final String? amount; // backend uses string sometimes
  final DateTime createdAt;
  final SlotModel? slot;

  BidModel({
    required this.id,
    this.userId,
    this.slotId,
    this.uniqueBidId,
    required this.customerName,
    this.customerPhone,
    this.number,
    this.count,
    this.jpNumbers,
    this.amount,
    required this.createdAt,
    this.slot,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    List<int>? parseJp(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => (e as num).toInt()).toList();
      if (v is String) return v.split('-').map((e) => int.parse(e)).toList();
      return null;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is String) return DateTime.parse(v).toLocal();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    return BidModel(
      id: (json['id'] ?? '') as String,
      userId: json['userId'] as String?,
      slotId: json['slotId'] as String?,
      uniqueBidId: json['uniqueBidId'] as String?,
      customerName: (json['customerName'] ?? '') as String,
      customerPhone: json['customerPhone'] as String?,
      number: json['number'] is num ? (json['number'] as num).toInt() : null,
      count: json['count'] is num ? (json['count'] as num).toInt() : null,
      jpNumbers: parseJp(json['jpNumbers']),
      amount: json['amount']?.toString(),
      createdAt: parseDate(json['createdAt']),
      slot: json['slot'] is Map<String, dynamic>
          ? SlotModel.fromJson(Map<String, dynamic>.from(json['slot']))
          : null,
    );
  }
}

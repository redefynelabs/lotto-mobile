class CreateBidDto {
  final String customerName;
  final String customerPhone;
  final String slotId;
  final int? number; // LD
  final int? count; // LD
  final List<int>? jpNumbers; // JP

  CreateBidDto({
    required this.customerName,
    required this.customerPhone,
    required this.slotId,
    this.number,
    this.count,
    this.jpNumbers,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'customerName': customerName,
      'customerPhone': customerPhone,
      'slotId': slotId,
    };
    if (number != null) map['number'] = number;
    if (count != null) map['count'] = count;
    if (jpNumbers != null) map['jpNumbers'] = jpNumbers;
    return map;
  }
}

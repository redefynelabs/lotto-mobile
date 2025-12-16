class WalletTx {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  WalletTx({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    required this.meta,
  });

  factory WalletTx.fromJson(Map<String, dynamic> json) {
    return WalletTx(
      id: json['id'] ?? "",
      type: json['type'] ?? "",
      amount: _parseDouble(json['amount']),
      balanceAfter: _parseDouble(json['balanceAfter']),
      createdAt: DateTime.parse(json['createdAt']),
      meta: json['meta'] ?? {},
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

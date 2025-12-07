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
      id: json['id'],
      type: json['type'],
      amount: json['amount']?.toDouble() ?? 0,
      balanceAfter: json['balanceAfter']?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      meta: json['meta'] ?? {},
    );
  }
}

class WalletBalance {
  final double totalBalance;
  final double reservedWinning;
  final double availableBalance;
  final double commissionEarned;
  final double commissionSettled;
  final double commissionPending;

  WalletBalance({
    required this.totalBalance,
    required this.reservedWinning,
    required this.availableBalance,
    required this.commissionEarned,
    required this.commissionSettled,
    required this.commissionPending,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      totalBalance: json['totalBalance']?.toDouble() ?? 0,
      reservedWinning: json['reservedWinning']?.toDouble() ?? 0,
      availableBalance: json['availableBalance']?.toDouble() ?? 0,
      commissionEarned: json['commissionEarned']?.toDouble() ?? 0,
      commissionSettled: json['commissionSettled']?.toDouble() ?? 0,
      commissionPending: json['commissionPending']?.toDouble() ?? 0,
    );
  }
}

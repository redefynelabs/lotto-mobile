import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/features/wallet/presentation/wallet_history_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../wallet/presentation/wallet_deposit_page.dart';
import '../../wallet/presentation/wallet_winning_page.dart';

class WalletHomePage extends ConsumerWidget {
  const WalletHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: balanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
          data: (balance) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BALANCE CARD
                _walletCard(balance),

                const SizedBox(height: 24),

                // Buttons
                _actionButton(
                  context,
                  "Request Deposit",
                  Icons.upload_file,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletDepositPage(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _actionButton(
                  context,
                  "Winning Settlement",
                  Icons.monetization_on,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletWinningPage(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _actionButton(
                  context,
                  "Wallet History",
                  Icons.history,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletHistoryPage(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _walletCard(balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Balance",
              style: TextStyle(fontSize: 14, color: Colors.black54)),
          Text(
            "₹${balance.totalBalance.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallStat("Reserved", "₹${balance.reservedWinning}"),
              _smallStat("Available", "₹${balance.availableBalance}"),
            ],
          ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallStat("Commission Earned", "₹${balance.commissionEarned}"),
              _smallStat("Pending", "₹${balance.commissionPending}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Wallet",
          style: TextStyle(
            color: Colors.black.withOpacity(0.85),
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",

            fontSize: 22,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: balanceAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text("Error: $e")),
          data: (balance) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _walletCard(balance),

                const SizedBox(height: 24),
                const Text(
                  "Actions",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    fontFamily: "Coolvetica",
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                _actionButton(
                  context,
                  "Request Deposit",
                  "assets/icons/wallet-add.svg",
                  AppColors.primary.withOpacity(0.12),
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
                  "assets/icons/money-send.svg",
                  Colors.green.withOpacity(0.12),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WinCreditSettlementPage(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _actionButton(
                  context,
                  "Wallet History",
                  "assets/icons/history.svg",
                  Colors.blueGrey.withOpacity(0.12),
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

  // -------------------------------
  // Wallet Summary Card
  // -------------------------------
  Widget _walletCard(balance) {
    final isNegative = balance.totalBalance < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Balance",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: "Coolvetica",
            ),
          ),
          Text(
            "RM ${balance.totalBalance.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isNegative ? AppColors.primary : Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallStat("Reserved", "RM ${balance.reservedWinning}"),
              _smallStat("Available", "RM ${balance.availableBalance}"),
            ],
          ),

          const Divider(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _smallStat("Commission Earned", "RM ${balance.commissionEarned}"),
              _smallStat("Pending", "RM ${balance.commissionPending}"),
            ],
          ),
        ],
      ),
    );
  }

  // Stat item with negative-number highlighting
  Widget _smallStat(String title, String value) {
    final isNegative = value.contains("-");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontFamily: "Coolvetica",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isNegative ? AppColors.primary : Colors.black,
            
          ),
        ),
      ],
    );
  }

  // ----------------------------------
  // Modern Action Button
  // ----------------------------------
  Widget _actionButton(
    BuildContext context,
    String title,
    String iconPath,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.black87,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: "Coolvetica",
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

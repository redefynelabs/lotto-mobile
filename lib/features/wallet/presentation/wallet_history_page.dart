import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/theme/app_colors.dart';

class WalletHistoryPage extends ConsumerWidget {
  const WalletHistoryPage({super.key});

  String formatMYT(DateTime utcTime) {
    final myt = utcTime.toUtc().add(const Duration(hours: 8));
    return DateFormat('dd MMM yyyy • hh:mm a').format(myt);
  }

  Color getTypeColor(String type) {
    switch (type) {
      case "DEPOSIT":
        return Colors.green;
      case "WITHDRAW":
        return Colors.red;
      case "WINNING":
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(walletHistoryProvider(1));

    return Scaffold(
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
        title: const Text(
          "Wallet History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",
            fontSize: 22,
          ),
        ),
      ),

      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (txList) {
          if (txList.isEmpty) {
            return const Center(
              child: Text("No history found", style: TextStyle(fontSize: 16)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txList.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey.shade300),
            itemBuilder: (_, i) {
              final tx = txList[i];
              final isCredit = tx.amount > 0;
              final color = isCredit ? Colors.green : Colors.red;

              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(
                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: color,
                  ),
                ),

                title: Text(
                  tx.type.replaceAll("_", " "),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: "Coolvetica",
                    fontSize: 16,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMYT(tx.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Balance After: RM ${tx.balanceAfter}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                trailing: Text(
                  "${isCredit ? "+" : "-"} RM ${tx.amount.abs()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

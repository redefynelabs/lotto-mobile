import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/models/wallet_tx_model.dart';
import 'package:win33/core/theme/app_colors.dart';
import 'package:win33/features/wallet/data/wallet_repository.dart';

final winCreditTxProvider = FutureProvider<List<WalletTx>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  final txList = await repo.getHistory(1, 300);

  return txList.where((tx) {
    return tx.type == "WIN_CREDIT" && (tx.meta["settled"] != true);
  }).toList();
});

class WinCreditSettlementPage extends ConsumerWidget {
  const WinCreditSettlementPage({super.key});

  String formatMYT(DateTime utcTime) {
    final myt = utcTime.toUtc().add(const Duration(hours: 8));
    return DateFormat('dd MMM yyyy • hh:mm a').format(myt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(walletRepositoryProvider);
    final winAsync = ref.watch(winCreditTxProvider);

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
          "Winning Bid Settlement",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",
            fontSize: 22,
          ),
        ),
      ),

      body: winAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                "No pending winning settlements",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final tx = list[i];
              final winId = tx.meta["winId"] ?? tx.id;
              final mytDate = formatMYT(tx.createdAt);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    // Text(
                    //   "Id: $winId",
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.w400,
                    //     fontSize: 16,
                    //   ),
                    // ),
                    const SizedBox(height: 10),

                    // HIGHLIGHTED AMOUNT
                    Text(
                      "RM ${tx.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (tx.meta["game"] != null)
                      Text(
                        "Game: ${tx.meta["game"]}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Text(
                      "Date: $mytDate",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          _openSettleDialog(context, repo, tx);
                        },
                        child: const Text(
                          "Settle",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openSettleDialog(
    BuildContext context,
    WalletRepository repo,
    WalletTx tx,
  ) {
    final amountCtrl = TextEditingController(text: tx.amount.toString());
    final transIdCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Settle RM ${tx.amount.toStringAsFixed(2)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: transIdCtrl,
              decoration: const InputDecoration(labelText: "Transaction ID"),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Note (optional)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await repo.agentSettleWinningToUser(
                amount: tx.amount,
                transId: transIdCtrl.text,
                note: noteCtrl.text,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Winning settled successfully")),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/providers/wallet_provider.dart';

class WalletHistoryPage extends ConsumerWidget {
  const WalletHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(walletHistoryProvider(1));

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet History")),

      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (txList) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final tx = txList[i];
              final isCredit = tx.amount > 0;
              final color = isCredit ? Colors.green : Colors.red;

              return ListTile(
                leading: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                ),
                title: Text(
                  "${tx.type.replaceAll("_", " ")}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${tx.createdAt}",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  "₹${tx.amount.abs()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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

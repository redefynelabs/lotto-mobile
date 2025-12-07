import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/providers/wallet_provider.dart';

class WalletDepositPage extends ConsumerStatefulWidget {
  const WalletDepositPage({super.key});

  @override
  ConsumerState<WalletDepositPage> createState() =>
      _WalletDepositPageState();
}

class _WalletDepositPageState extends ConsumerState<WalletDepositPage> {
  final amountCtrl = TextEditingController();
  final transIdCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(walletRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Deposit"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: transIdCtrl,
              decoration: const InputDecoration(
                labelText: "Transaction ID",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: "Note (optional)",
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await repo.requestDeposit(
                          amount: double.parse(amountCtrl.text),
                          transId: transIdCtrl.text,
                          note: noteCtrl.text,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Deposit requested")),
                          );
                          Navigator.pop(context);
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}

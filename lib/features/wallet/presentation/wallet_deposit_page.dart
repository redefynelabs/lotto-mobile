import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:win33/app/providers/wallet_provider.dart';
import 'package:win33/core/theme/app_colors.dart';

class WalletDepositPage extends ConsumerStatefulWidget {
  const WalletDepositPage({super.key});

  @override
  ConsumerState<WalletDepositPage> createState() => _WalletDepositPageState();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          iconSize: 20,
          icon: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            width: 22,
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Request Deposit",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontFamily: "Coolvetica",

            fontSize: 22,
          ),
        ),
      ),

      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter deposit details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Coolvetica",
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount field
                  _inputCard(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Amount (RM)",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Transaction ID
                  _inputCard(
                    child: TextField(
                      controller: transIdCtrl,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Transaction ID",
                        labelStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Note
                  _inputCard(
                    child: TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: "Note (optional)",
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom fixed button
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (amountCtrl.text.isEmpty ||
                          double.tryParse(amountCtrl.text) == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter a valid amount")),
                        );
                        return;
                      }

                      if (transIdCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Transaction ID is required"),
                          ),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        await repo.requestDeposit(
                          amount: double.parse(amountCtrl.text),
                          transId: transIdCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Deposit request submitted"),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Coolvetica",
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Extract UI card for reuse
  Widget _inputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

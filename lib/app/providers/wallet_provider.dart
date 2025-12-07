import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/core/models/wallet_balance_model.dart';
import 'package:win33/core/models/wallet_tx_model.dart';
import 'package:win33/features/wallet/data/wallet_repository.dart';

final walletRepositoryProvider = Provider((_) => WalletRepository());

final walletBalanceProvider = FutureProvider<WalletBalance>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getBalance();
});

final walletHistoryProvider = FutureProvider.family<List<WalletTx>, int>((ref, page) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getHistory(page, 50);
});



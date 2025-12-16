import 'package:dio/dio.dart';
import 'package:win33/core/models/wallet_balance_model.dart';
import 'package:win33/core/models/wallet_tx_model.dart';
import 'package:win33/core/network/dio_client.dart';

class WalletRepository {
  final Dio _client = DioClient.dio;

  Future<WalletBalance> getBalance() async {
    // print(">>> WALLET: calling /wallet/balance");

    final res = await _client.get("/wallet/balance");

    // print(">>> WALLET response: ${res.data}");

    return WalletBalance.fromJson(res.data);
  }

  Future<List<WalletTx>> getHistory(int page, int pageSize) async {
    final res = await _client.get(
      "/wallet/history",
      queryParameters: {"page": page, "pageSize": pageSize},
    );

    final items = (res.data["items"] as List)
        .map((e) => WalletTx.fromJson(e))
        .toList();

    return items;
  }

  Future<dynamic> requestDeposit({
    required double amount,
    required String transId,
    String? proofUrl,
    String? note,
  }) async {
    final res = await _client.post(
      "/wallet/deposit/request",
      data: {
        "amount": amount,
        "transId": transId,
        "proofUrl": proofUrl,
        "note": note,
      },
    );

    return res.data;
  }

  Future<dynamic> agentSettleWinningToUser({
    required double amount,
    required String transId,
    String? proofUrl,
    String? note,
  }) async {
    final res = await _client.post(
      "/wallet/agent/win/settle-to-user",
      data: {
        "amount": amount,
        "transId": transId,
        "proofUrl": proofUrl,
        "note": note,
      },
    );
    return res.data;
  }
}

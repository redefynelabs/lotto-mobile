import 'package:dio/dio.dart';
import 'package:win33/core/network/dio_client.dart';
import 'package:win33/features/bid/data/model/bid_model.dart';
import 'package:win33/features/bid/data/model/create_bid_dto.dart';

class BiddingRepository {
  BiddingRepository._internal();
  static final BiddingRepository instance = BiddingRepository._internal();

  final Dio _dio = DioClient.dio;

  Future<void> createBid(CreateBidDto dto) async {
    final res = await _dio.post('/bids/create', data: dto.toJson());
    if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
      throw Exception('Create bid failed: ${res.statusCode}');
    }
  }

  Future<List<BidModel>> getMyBids() async {
    final res = await _dio.get("/bids/my");

    if (res.statusCode == 200) {
      final items = res.data["items"] as List<dynamic>;
      return items.map((e) => BidModel.fromJson(e)).toList();
    }

    throw Exception("Failed to load bids (${res.statusCode})");
  }
}

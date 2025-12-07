import 'package:win33/core/network/dio_client.dart';
import 'package:win33/features/results/data/models/result_model.dart';

class ResultsRepository {
  final dio = DioClient.dio;

  /// Fetch latest results (list)
  Future<List<ResultModel>> fetchResults(String type, {int limit = 50}) async {
    final res = await dio.get(
      '/results',
      queryParameters: {'type': type, 'limit': limit},
    );

    final data = res.data as List;
    return data.map((e) => ResultModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch results by MYT date (backend returns { date, LD: [...], JP: [...] })
  Future<List<ResultModel>> fetchResultsByDate(String dateString, String type) async {
    final res = await dio.get(
      '/results/by-date',
      queryParameters: {'date': dateString},
    );

    final body = res.data as Map<String, dynamic>;
    final list = (body[type] as List?) ?? [];
    return list.map((e) => ResultModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

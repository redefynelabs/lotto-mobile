import 'package:dio/dio.dart';
import 'package:win33/core/network/dio_client.dart';
import 'package:win33/features/bid/data/model/slot_model.dart';

class SlotRepository {
  SlotRepository._internal();
  static final SlotRepository instance = SlotRepository._internal();

  final Dio _dio = DioClient.dio;

  /// ---------------------------------------------------------------------------
  /// OLD METHOD: GROUPED SLOTS (keep it)
  /// GET /slots/grouped-by-date
  /// ---------------------------------------------------------------------------
  Future<Map<String, List<SlotModel>>> getSlotsGroupedByDate() async {
    final res = await _dio.get('/slots/grouped-by-date');
    if (res.statusCode == 200) {
      final data = res.data as Map<String, dynamic>;
      final Map<String, List<SlotModel>> grouped = {};

      data.forEach((key, value) {
        grouped[key] =
            (value as List).map((e) => SlotModel.fromJson(e)).toList();
      });

      return grouped;
    }
    throw Exception('Failed to load slots (${res.statusCode})');
  }

  /// ---------------------------------------------------------------------------
  /// NEW METHOD: GET TODAY/DATE SPECIFIC SLOTS
  /// GET /slots/by-date?date=YYYY-MM-DD
  /// Returns:
  /// {
  ///   "date": "...",
  ///   "LD": [...],
  ///   "JP": [...]
  /// }
  /// ---------------------------------------------------------------------------
  Future<Map<String, List<SlotModel>>> getSlotsByDate(String date) async {
    final res = await _dio.get(
      '/slots/by-date',
      queryParameters: {'date': date},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load slots for $date (${res.statusCode})");
    }

    final body = res.data as Map<String, dynamic>;

    final ldList = (body["LD"] as List? ?? [])
        .map((e) => SlotModel.fromJson(e))
        .toList();

    final jpList = (body["JP"] as List? ?? [])
        .map((e) => SlotModel.fromJson(e))
        .toList();

    return {
      "LD": ldList,
      "JP": jpList,
    };
  }
}

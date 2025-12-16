import 'slot_model.dart';

class GroupedSlotsResponse {
  final Map<String, List<SlotModel>> grouped;
  GroupedSlotsResponse(this.grouped);

  factory GroupedSlotsResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, List<SlotModel>> parsed = {};
    json.forEach((key, value) {
      parsed[key] = (value as List).map((e) => SlotModel.fromJson(e as Map<String, dynamic>)).toList();
    });
    return GroupedSlotsResponse(parsed);
  }
}
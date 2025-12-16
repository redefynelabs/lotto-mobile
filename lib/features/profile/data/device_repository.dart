import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/core/network/dio_client.dart';

class DeviceRepository {
  final _dio = DioClient.dio;

  /// GET /auth/devices
  Future<List<dynamic>> getDevices() async {
    final res = await _dio.get("/auth/devices");
    return res.data;
  }

  /// DELETE /auth/devices/:deviceId
  Future<void> revokeDevice(String deviceId) async {
    await _dio.delete("/auth/devices/$deviceId");
  }
}

final deviceRepoProvider = Provider((ref) => DeviceRepository());

final deviceListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(deviceRepoProvider).getDevices();
});

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const FlutterSecureStorage _store = FlutterSecureStorage();

  static Future<void> write(String key, String value) async {
    await _store.write(key: key, value: value);
  }

  static Future<String?> read(String key) async {
    return await _store.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _store.delete(key: key);
  }

  static Future<void> clear() async {
    await _store.deleteAll();
  }
}

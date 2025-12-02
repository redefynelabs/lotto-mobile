import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/dio_client.dart';
import 'api/token_store.dart';
import 'api/auth_interceptor.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) {
  final store = TokenStore();
  store.load();
  return store;
});

final dioProvider = Provider<DioClient>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  final dioClient = DioClient(
    'https://server.lotto.redefyne.in/api',
    interceptors: [
      AuthInterceptor(tokenStore, Dio()),
    ],
  );
  return dioClient;
});

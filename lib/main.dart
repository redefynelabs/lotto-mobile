import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:win33/app/app.dart';
import 'package:win33/core/network/app_token_manager.dart';
import 'package:win33/core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppTokenManager.instance.load();
  await DioClient.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

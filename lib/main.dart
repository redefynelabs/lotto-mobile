import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win33/app/app.dart';
import 'package:win33/core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first
  await SharedPreferences.getInstance();

  // Now initialize Dio + tokens
  await DioClient.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
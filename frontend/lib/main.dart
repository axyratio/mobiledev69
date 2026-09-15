import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStore = await SessionStore.create();
  final apiClient = await ApiClient.create(cookieJar: sessionStore.cookieJar);
  runApp(StoryGeneratorApp(apiClient: apiClient, sessionStore: sessionStore));
}

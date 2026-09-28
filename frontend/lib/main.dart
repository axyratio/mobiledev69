import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/session_store.dart';
import 'core/auth/token_store.dart';
import 'core/web/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No-op outside web: drops the "#" from web URLs (e.g. /my-stories
  // instead of /#/my-stories). Requires the host to rewrite every path to
  // index.html — see the Render static site rewrite rule.
  configureUrlStrategy();
  final sessionStore = await SessionStore.create();
  final tokenStore = TokenStore.create();
  final apiClient = await ApiClient.create(
    cookieJar: sessionStore.cookieJar,
    tokenStore: tokenStore,
  );
  runApp(
    StoryGeneratorApp(
      apiClient: apiClient,
      sessionStore: sessionStore,
      tokenStore: tokenStore,
    ),
  );
}

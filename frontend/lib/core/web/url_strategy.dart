// Drops the "#" from web URLs (`/my-stories` instead of `/#/my-stories`).
//
// `flutter_web_plugins` pulls in `dart:ui_web`, which only exists on the
// web compile target — importing it directly from a file also compiled
// for mobile/desktop fails outright ("Dart library 'dart:ui_web' is not
// available on this platform"). This conditional export picks the real
// implementation only when compiling for web, and a no-op everywhere
// else, so `configureUrlStrategy()` is safe to call from shared `main.dart`.
export 'url_strategy_stub.dart' if (dart.library.js_interop) 'url_strategy_web.dart';

import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase Analytics and Crashlytics on supported platforms.
class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  FirebaseAnalytics? get analytics => _analytics;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;

    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;

      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await _analytics?.logAppOpen();
      _initialized = true;
    } catch (e, stack) {
      debugPrint('Firebase initialization failed: $e\n$stack');
    }
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) async {
    if (!_initialized) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: fatal,
    );
  }
}

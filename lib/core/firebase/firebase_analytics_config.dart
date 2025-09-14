import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsConfig {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  static FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Firebase Analytics not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  static FirebaseAnalyticsObserver get observer {
    if (_observer == null) {
      throw Exception('Firebase Analytics not initialized. Call initialize() first.');
    }
    return _observer!;
  }

  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Configure analytics settings
      await _analytics!.setAnalyticsCollectionEnabled(true);
      await _analytics!.setUserId(id: 'metriagro_user');

      // Firebase Analytics initialized successfully
    } catch (e) {
      // Error initializing Firebase Analytics: $e
    }
  }

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Error logging event: $e
    }
  }

  static Future<void> logLogin({String? method}) async {
    await logEvent('login', parameters: {'method': method ?? 'unknown'});
  }

  static Future<void> logSignUp({String? method}) async {
    await logEvent('sign_up', parameters: {'method': method ?? 'unknown'});
  }

  static Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }
}

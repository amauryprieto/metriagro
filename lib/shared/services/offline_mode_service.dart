import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user preference for offline/online mode.
///
/// When offline mode is enabled, all text queries will be processed locally
/// using the SQLite database and local ML models, even if internet is available.
class OfflineModeService {
  static const String _offlineModeKey = 'force_offline_mode';

  final StreamController<bool> _modeController = StreamController<bool>.broadcast();

  bool _isOfflineMode = false;

  /// Stream of offline mode changes
  Stream<bool> get offlineModeStream => _modeController.stream;

  /// Current offline mode status
  bool get isOfflineMode => _isOfflineMode;

  /// Initialize the service and load saved preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(_offlineModeKey) ?? false;
    _modeController.add(_isOfflineMode);
  }

  /// Toggle offline mode
  Future<void> toggleOfflineMode() async {
    await setOfflineMode(!_isOfflineMode);
  }

  /// Set offline mode explicitly
  Future<void> setOfflineMode(bool enabled) async {
    _isOfflineMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, enabled);
    _modeController.add(_isOfflineMode);
  }

  /// Dispose the service
  void dispose() {
    _modeController.close();
  }
}

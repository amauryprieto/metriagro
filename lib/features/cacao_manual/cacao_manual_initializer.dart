import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasources/cacao_manual_seeder.dart';
import '../../core/di/injection_container.dart';

class CacaoManualInitializer {
  static const String _seedVersionKey = 'cacao_manual_seed_version';
  static const int _currentSeedVersion = 1;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final seedVersion = prefs.getInt(_seedVersionKey) ?? 0;

    if (seedVersion < _currentSeedVersion) {
      await _seedDatabase();
      await prefs.setInt(_seedVersionKey, _currentSeedVersion);
    }
  }

  static Future<void> _seedDatabase() async {
    final seeder = sl<CacaoManualSeeder>();
    await seeder.seedDatabase();
  }

  static Future<void> forceReseed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedVersionKey);
    await initialize();
  }
}

import 'data/datasources/cacao_manual_database.dart';

/// Initializes the Cacao Manual database.
///
/// The database is pre-built and shipped as an asset. On first launch
/// (or when updated), it's copied from assets to the app's database directory.
///
/// Usage in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await CacaoManualInitializer.initialize();
///   runApp(const MyApp());
/// }
/// ```
class CacaoManualInitializer {
  /// Initialize the cacao manual database.
  /// This will copy the pre-built database from assets if needed.
  static Future<void> initialize() async {
    // Simply access the database - this triggers the copy from assets if needed
    await CacaoManualDatabase.instance.database;
  }

  /// Force reset the database from assets.
  /// Useful for debugging or when you need to restore the original data.
  static Future<void> forceReset() async {
    await CacaoManualDatabase.instance.resetFromAssets();
  }

  /// Check if database needs to be updated from assets.
  static Future<bool> needsUpdate() async {
    return await CacaoManualDatabase.instance.needsUpdate();
  }

  /// Get the currently installed database version.
  static Future<int> getInstalledVersion() async {
    return await CacaoManualDatabase.instance.getInstalledVersion();
  }
}

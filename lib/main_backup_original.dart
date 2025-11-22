import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_options.dart';
import 'core/firebase/firebase_analytics_config.dart';
import 'features/auth/presentation/pages/simple_welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Analytics
  await FirebaseAnalyticsConfig.initialize();

  // Initialize Hive
  // await Hive.initFlutter();

  // Configure dependencies
  // await configureDependencies();

  runApp(const MetriagroApp());
}

class MetriagroApp extends StatelessWidget {
  const MetriagroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metriagro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SimpleWelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
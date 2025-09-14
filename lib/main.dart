import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/simple_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Configure dependencies
  await configureDependencies();

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
      home: const SimpleLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

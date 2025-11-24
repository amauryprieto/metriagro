import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_options.dart';
import 'core/firebase/firebase_analytics_config.dart';
import 'features/consultation/presentation/pages/conversational_consultation_page.dart';
import 'core/di/injection_container.dart';
import 'features/conversation/presentation/bloc/conversation_bloc.dart';
import 'features/conversation/domain/conversation_engine.dart';
import 'shared/services/tts_speaker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[MAIN] WidgetsFlutterBinding initialized');

  try {
    // Initialize Firebase
    print('[MAIN] Initializing Firebase...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('[MAIN] Firebase initialized');

    // Initialize Firebase Analytics
    print('[MAIN] Initializing Firebase Analytics...');
    await FirebaseAnalyticsConfig.initialize();
    print('[MAIN] Firebase Analytics initialized');

    // Initialize Hive
    // await Hive.initFlutter();

    // Configure dependencies
    print('[MAIN] Configuring dependencies...');
    await configureDependencies();
    print('[MAIN] Dependencies configured');

    print('[MAIN] Starting app...');
    runApp(const MetriagroApp());
  } catch (e, stackTrace) {
    print('[MAIN] ERROR: $e');
    print('[MAIN] Stack trace: $stackTrace');
    rethrow;
  }
}

class MetriagroApp extends StatelessWidget {
  const MetriagroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ConversationBloc(engine: sl<ConversationEngine>(), tts: sl<TtsSpeaker>())..add(const ConversationStarted()),
      child: MaterialApp(
        title: 'Metriagro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const ConversationalConsultationPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

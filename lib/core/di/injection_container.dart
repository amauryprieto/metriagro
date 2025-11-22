import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/network_info.dart';
import '../services/ml_inference_service.dart';
import '../services/gcp_disease_api_service.dart';
import '../../features/conversation/domain/conversation_engine.dart';
import '../../shared/services/vision_router.dart' as shared_vision;
import '../../shared/models/conversation_models.dart' show CropType;
import '../../shared/services/vision_classifiers.dart';
import '../../shared/services/local_knowledge_base.dart';
import '../../shared/services/audio_transcriber.dart';
import '../../shared/services/tts_speaker.dart';
import '../../shared/services/history_storage.dart';

// Cacao Manual imports
import '../../features/cacao_manual/data/datasources/cacao_manual_database.dart';
import '../../features/cacao_manual/data/datasources/cacao_manual_local_datasource.dart';
import '../../features/cacao_manual/data/datasources/cacao_manual_seeder.dart';
import '../../features/cacao_manual/data/repositories/cacao_manual_repository_impl.dart';
import '../../features/cacao_manual/domain/repositories/cacao_manual_repository.dart';
import '../../features/cacao_manual/domain/usecases/search_manual.dart';
import '../../features/cacao_manual/domain/usecases/get_sections_by_ml_class.dart';
import '../../features/cacao_manual/domain/usecases/get_combined_diagnosis.dart';
import '../../features/cacao_manual/domain/usecases/get_section_by_id.dart';
import '../../features/cacao_manual/domain/usecases/get_all_chapters.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<MlInferenceService>(() => LocalTfliteInferenceService());
  sl.registerLazySingleton<GcpDiseaseApiService>(() => GcpDiseaseApiServiceImpl(sl()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());

  // Vision Router with a basic classifier (choose one crop as default, can be extended)
  sl.registerLazySingleton<shared_vision.VisionRouter>(() {
    final router = shared_vision.VisionRouter(
      classifiers: [
        // MVP: solo cacao
        TfliteDiseaseClassifier(mlService: sl<MlInferenceService>(), supportedCropType: CropType.cacao),
      ],
    );
    return router;
  });

  // Local Knowledge Base
  sl.registerLazySingleton<LocalKnowledgeBase>(() => SqliteKnowledgeBase());

  // History storage
  sl.registerLazySingleton<HistoryStorage>(() => SqliteHistoryStorage());

  // Audio Transcriber
  sl.registerLazySingleton<AudioTranscriber>(() => SpeechToTextTranscriber());
  // TTS
  sl.registerLazySingleton<TtsSpeaker>(() => FlutterTtsSpeaker());

  // Conversation Engines
  sl.registerLazySingleton<ConversationEngine>(
    () => ConversationRouter(
      onlineEngine: OnlineConversationService(),
      offlineEngine: OfflineConversationService(
        audioTranscriber: sl<AudioTranscriber>(),
        visionRouter: sl<shared_vision.VisionRouter>(),
        localKB: sl<LocalKnowledgeBase>(),
      ),
      connectivityService: sl<ConnectivityService>(),
    ),
  );

  // External
  sl.registerLazySingleton(() => SharedPreferences.getInstance());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseAnalytics.instance);
  sl.registerLazySingleton(() => FirebaseCrashlytics.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);

  // HTTP Client
  sl.registerLazySingleton(() => Dio());

  // Analytics
  sl.registerLazySingletonAsync<Mixpanel>(() async {
    return await Mixpanel.init(
      'YOUR_MIXPANEL_TOKEN', // TODO: Replace with actual token
      trackAutomaticEvents: true,
    );
  });

  // Cacao Manual Feature
  await _registerCacaoManualFeature();
}

Future<void> _registerCacaoManualFeature() async {
  // Database
  sl.registerLazySingleton<CacaoManualDatabase>(() => CacaoManualDatabase.instance);

  // Data sources
  sl.registerLazySingleton<CacaoManualLocalDataSource>(
    () => CacaoManualLocalDataSourceImpl(databaseHelper: sl()),
  );

  // Seeder
  sl.registerLazySingleton<CacaoManualSeeder>(
    () => CacaoManualSeeder(sl()),
  );

  // Repository
  sl.registerLazySingleton<CacaoManualRepository>(
    () => CacaoManualRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SearchManual(sl()));
  sl.registerLazySingleton(() => GetSectionsByMlClass(sl()));
  sl.registerLazySingleton(() => GetCombinedDiagnosis(sl()));
  sl.registerLazySingleton(() => GetSectionById(sl()));
  sl.registerLazySingleton(() => GetAllChapters(sl()));
}

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
import '../../shared/services/offline_mode_service.dart';
import '../../shared/services/embedding_cache.dart';
import '../../shared/services/distiluse_embedding_service.dart';
import '../services/text_embedding_service.dart';

// Cacao Manual imports
import '../../features/cacao_manual/data/datasources/cacao_manual_database.dart';
import '../../features/cacao_manual/data/datasources/cacao_manual_local_datasource.dart';
import '../../features/cacao_manual/data/datasources/cacao_manual_seeder.dart';
import '../../features/cacao_manual/data/datasources/vector_search_datasource.dart';
import '../../features/cacao_manual/data/repositories/cacao_manual_repository_impl.dart';
import '../../features/cacao_manual/domain/repositories/cacao_manual_repository.dart';
import '../../features/cacao_manual/domain/usecases/search_manual.dart';
import '../../features/cacao_manual/domain/usecases/get_sections_by_ml_class.dart';
import '../../features/cacao_manual/domain/usecases/get_combined_diagnosis.dart';
import '../../features/cacao_manual/domain/usecases/get_section_by_id.dart';
import '../../features/cacao_manual/domain/usecases/get_all_chapters.dart';
import '../../features/cacao_manual/domain/usecases/semantic_search.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  print('[DI] Starting configureDependencies...');

  // Initialize Hive (Firebase already initialized in main.dart)
  print('[DI] Initializing Hive...');
  await Hive.initFlutter();
  print('[DI] Hive initialized');

  // Core
  print('[DI] Registering Core services...');
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<MlInferenceService>(() => LocalTfliteInferenceService());
  sl.registerLazySingleton<GcpDiseaseApiService>(() => GcpDiseaseApiServiceImpl(sl()));
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityServiceImpl());
  print('[DI] Core services registered');

  // Vision Router with a basic classifier (choose one crop as default, can be extended)
  print('[DI] Registering VisionRouter...');
  sl.registerLazySingleton<shared_vision.VisionRouter>(() {
    final router = shared_vision.VisionRouter(
      classifiers: [
        // MVP: solo cacao
        TfliteDiseaseClassifier(mlService: sl<MlInferenceService>(), supportedCropType: CropType.cacao),
      ],
    );
    return router;
  });
  print('[DI] VisionRouter registered');

  // Local Knowledge Base
  print('[DI] Registering LocalKnowledgeBase...');
  sl.registerLazySingleton<LocalKnowledgeBase>(() => SqliteKnowledgeBase());
  print('[DI] LocalKnowledgeBase registered');

  // History storage
  print('[DI] Registering HistoryStorage...');
  sl.registerLazySingleton<HistoryStorage>(() => SqliteHistoryStorage());
  print('[DI] HistoryStorage registered');

  // Audio Transcriber
  print('[DI] Registering AudioTranscriber...');
  sl.registerLazySingleton<AudioTranscriber>(() => SpeechToTextTranscriber());
  print('[DI] AudioTranscriber registered');

  // TTS
  print('[DI] Registering TtsSpeaker...');
  sl.registerLazySingleton<TtsSpeaker>(() => FlutterTtsSpeaker());
  print('[DI] TtsSpeaker registered');

  // Offline Mode Service
  print('[DI] Registering OfflineModeService...');
  sl.registerLazySingleton<OfflineModeService>(() => OfflineModeService());
  print('[DI] OfflineModeService registered');

  // Cacao Manual Feature (must be registered before ConversationEngine for vector search)
  print('[DI] Registering CacaoManualFeature...');
  await _registerCacaoManualFeature();
  print('[DI] CacaoManualFeature registered');

  // Conversation Engines (after cacao manual so VectorSearchDataSource is available)
  print('[DI] Registering ConversationEngine...');
  sl.registerLazySingleton<ConversationEngine>(
    () => ConversationRouter(
      onlineEngine: OnlineConversationService(),
      offlineEngine: OfflineConversationService(
        audioTranscriber: sl<AudioTranscriber>(),
        visionRouter: sl<shared_vision.VisionRouter>(),
        localKB: sl<LocalKnowledgeBase>(),
        vectorSearch: sl.isRegistered<VectorSearchDataSource>()
            ? sl<VectorSearchDataSource>()
            : null,
      ),
      connectivityService: sl<ConnectivityService>(),
      offlineModeService: sl<OfflineModeService>(),
    ),
  );
  print('[DI] ConversationEngine registered');

  // External
  print('[DI] Registering External services...');
  sl.registerLazySingleton(() => SharedPreferences.getInstance());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseAnalytics.instance);
  sl.registerLazySingleton(() => FirebaseCrashlytics.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);
  print('[DI] External services registered');

  // HTTP Client
  print('[DI] Registering Dio...');
  sl.registerLazySingleton(() => Dio());
  print('[DI] Dio registered');

  // Analytics
  print('[DI] Registering Mixpanel...');
  sl.registerLazySingletonAsync<Mixpanel>(() async {
    return await Mixpanel.init(
      'YOUR_MIXPANEL_TOKEN', // TODO: Replace with actual token
      trackAutomaticEvents: true,
    );
  });
  print('[DI] Mixpanel registered');

  print('[DI] configureDependencies complete!');
}

Future<void> _registerCacaoManualFeature() async {
  print('[DI-Cacao] Starting _registerCacaoManualFeature...');

  // Database
  print('[DI-Cacao] Registering CacaoManualDatabase...');
  sl.registerLazySingleton<CacaoManualDatabase>(() => CacaoManualDatabase.instance);
  print('[DI-Cacao] CacaoManualDatabase registered');

  // Data sources
  print('[DI-Cacao] Registering CacaoManualLocalDataSource...');
  sl.registerLazySingleton<CacaoManualLocalDataSource>(
    () => CacaoManualLocalDataSourceImpl(databaseHelper: sl()),
  );
  print('[DI-Cacao] CacaoManualLocalDataSource registered');

  // Seeder
  print('[DI-Cacao] Registering CacaoManualSeeder...');
  sl.registerLazySingleton<CacaoManualSeeder>(
    () => CacaoManualSeeder(sl()),
  );
  print('[DI-Cacao] CacaoManualSeeder registered');

  // Repository
  print('[DI-Cacao] Registering CacaoManualRepository...');
  sl.registerLazySingleton<CacaoManualRepository>(
    () => CacaoManualRepositoryImpl(localDataSource: sl()),
  );
  print('[DI-Cacao] CacaoManualRepository registered');

  // Embedding services for semantic search (optional - requires TFLite model)
  // These services will be available once the model files are added to assets/models/
  print('[DI-Cacao] Registering EmbeddingCache...');
  sl.registerLazySingleton<EmbeddingCache>(() => EmbeddingCache(maxSize: 100));
  print('[DI-Cacao] EmbeddingCache registered');

  // Note: VectorSearchDataSource and TextEmbeddingService are not registered until
  // the TFLite model (distiluse_base.tflite) and vocab.txt are added to assets/models/
  // TODO: Uncomment when model files are available:
  // sl.registerLazySingleton<TextEmbeddingService>(() => DistilUseEmbeddingService());
  // sl.registerLazySingleton<VectorSearchDataSource>(
  //   () => VectorSearchDataSource(
  //     database: sl<CacaoManualDatabase>(),
  //     embeddingService: sl<TextEmbeddingService>(),
  //     cache: sl<EmbeddingCache>(),
  //   ),
  // );

  // Use cases
  print('[DI-Cacao] Registering Use Cases...');
  sl.registerLazySingleton(() => SearchManual(sl()));
  sl.registerLazySingleton(() => GetSectionsByMlClass(sl()));
  sl.registerLazySingleton(() => GetCombinedDiagnosis(sl()));
  sl.registerLazySingleton(() => GetSectionById(sl()));
  sl.registerLazySingleton(() => GetAllChapters(sl()));
  print('[DI-Cacao] Use Cases registered');
  // TODO: Uncomment when model files are available:
  // sl.registerLazySingleton(() => SemanticSearch(sl<VectorSearchDataSource>()));

  print('[DI-Cacao] _registerCacaoManualFeature complete!');
}

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
}

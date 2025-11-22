class AppConstants {
  // App Info
  static const String appName = 'Metriagro';
  static const String appVersion = '1.0.0';

  // API Constants
  static const String baseUrl = 'https://api.metriagro.com';
  static const String gcpDiseaseEndpoint = '/api/v1/disease-analysis';
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String farmsCollection = 'farms';
  static const String measurementsCollection = 'measurements';

  // ML Model Constants
  static const String tfliteModelPath = 'assets/models/';
  static const String modelFileName = 'crop_analysis_model.tflite';
  static const String labelsFileName = 'labels.txt';

  // Analytics Events
  static const String loginEvent = 'user_login';
  static const String logoutEvent = 'user_logout';
  static const String measurementEvent = 'crop_measurement';
}

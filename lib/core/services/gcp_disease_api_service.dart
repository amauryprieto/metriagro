import 'dart:io';

import 'package:dio/dio.dart';

import '../../shared/models/disease_detection_result.dart';
import '../constants/app_constants.dart';

abstract class GcpDiseaseApiService {
  Future<DiseaseDetectionResult> uploadAndAnalyze(File imageFile);
}

class GcpDiseaseApiServiceImpl implements GcpDiseaseApiService {
  final Dio _dio;

  GcpDiseaseApiServiceImpl(this._dio) {
    _dio
      ..options.baseUrl = AppConstants.baseUrl
      ..options.connectTimeout = const Duration(milliseconds: AppConstants.connectionTimeout)
      ..options.receiveTimeout = const Duration(milliseconds: AppConstants.receiveTimeout);
  }

  @override
  Future<DiseaseDetectionResult> uploadAndAnalyze(File imageFile) async {
    final fileName = imageFile.path.split('/').last;

    final formData = FormData.fromMap({'file': await MultipartFile.fromFile(imageFile.path, filename: fileName)});

    final response = await _dio.post(
      AppConstants.gcpDiseaseEndpoint,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : (response.data as Map).cast<String, dynamic>();

    return DiseaseDetectionResult.fromJson(data);
  }
}

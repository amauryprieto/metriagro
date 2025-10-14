import 'package:equatable/equatable.dart';
import 'dart:typed_data';

/// Tipo de entrada del usuario
enum InputType {
  text,
  audio,
  image,
  multimodal, // Combinación de texto/audio + imagen
}

/// Tipo de cultivo detectado
enum CropType {
  cacao,
  cafe,
  platano,
  maiz,
  unknown,
}

/// Nivel de confianza en la detección
enum ConfidenceLevel {
  high,    // > 90%
  medium,  // 70-90%
  low,     // 50-70%
  unknown, // < 50%
}

/// Solicitud de conversación unificada
class ConversationRequest extends Equatable {
  final String? textInput;
  final Uint8List? audioData;
  final Uint8List? imageData;
  final InputType inputType;
  final CropType? expectedCropType; // Hint del usuario sobre el cultivo
  
  const ConversationRequest({
    this.textInput,
    this.audioData,
    this.imageData,
    required this.inputType,
    this.expectedCropType,
  });

  bool get hasText => textInput != null && textInput!.isNotEmpty;
  bool get hasAudio => audioData != null;
  bool get hasImage => imageData != null;
  bool get isMultimodal => hasImage && (hasText || hasAudio);

  @override
  List<Object?> get props => [
    textInput,
    audioData,
    imageData,
    inputType,
    expectedCropType,
  ];
}

/// Resultado de clasificación de imagen
class VisionResult extends Equatable {
  final String diseaseId;
  final String diseaseName;
  final CropType cropType;
  final double confidence;
  final ConfidenceLevel confidenceLevel;
  final Map<String, dynamic>? metadata;

  const VisionResult({
    required this.diseaseId,
    required this.diseaseName,
    required this.cropType,
    required this.confidence,
    required this.confidenceLevel,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    diseaseId,
    diseaseName,
    cropType,
    confidence,
    confidenceLevel,
    metadata,
  ];
}

/// Información de tratamiento de una enfermedad
class TreatmentInfo extends Equatable {
  final String treatmentId;
  final String title;
  final String description;
  final List<String> products;
  final List<String> steps;
  final Map<String, String>? additionalInfo;

  const TreatmentInfo({
    required this.treatmentId,
    required this.title,
    required this.description,
    required this.products,
    required this.steps,
    this.additionalInfo,
  });

  @override
  List<Object?> get props => [
    treatmentId,
    title,
    description,
    products,
    steps,
    additionalInfo,
  ];
}

/// Respuesta unificada del sistema conversacional
class ConversationResponse extends Equatable {
  final String responseText;
  final VisionResult? visionResult;
  final TreatmentInfo? treatmentInfo;
  final bool isFromOnlineService;
  final DateTime timestamp;
  final Map<String, dynamic>? debugInfo;

  const ConversationResponse({
    required this.responseText,
    this.visionResult,
    this.treatmentInfo,
    required this.isFromOnlineService,
    required this.timestamp,
    this.debugInfo,
  });

  @override
  List<Object?> get props => [
    responseText,
    visionResult,
    treatmentInfo,
    isFromOnlineService,
    timestamp,
    debugInfo,
  ];
}

/// Error en el procesamiento de la conversación
class ConversationError extends Equatable {
  final String message;
  final String? errorCode;
  final Exception? originalError;

  const ConversationError({
    required this.message,
    this.errorCode,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, errorCode, originalError];
}
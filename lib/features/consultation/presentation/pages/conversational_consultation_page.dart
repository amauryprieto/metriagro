import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metriagro/core/theme/app_theme.dart';
import 'package:metriagro/core/di/injection_container.dart';
import '../../../conversation/presentation/bloc/conversation_bloc.dart';
import '../../../../shared/models/conversation_models.dart';
import '../../../../shared/services/whisper_transcriber.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../shared/services/history_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:image/image.dart' as img;

/// PROPUESTA 3: INTERFAZ CONVERSACIONAL
/// Enfoque: Chat/asistente, interacción natural, flujo conversacional
///
/// Características:
/// - Interfaz tipo chat/mensaje
/// - Asistente que guía la conversación
/// - Input multimodal integrado en el chat
/// - Historial como conversaciones
/// - Respuestas progresivas y contextuales
/// - Experiencia más humana y natural

class ConversationalConsultationPage extends StatefulWidget {
  const ConversationalConsultationPage({super.key});

  @override
  State<ConversationalConsultationPage> createState() => _ConversationalConsultationPageState();
}

class _ConversationalConsultationPageState extends State<ConversationalConsultationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    // Mensaje de bienvenida del asistente
    _messages.addAll([
      ChatMessage(
        text: '¡Hola! Soy tu asistente agrícola de Metriagro 🌱',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: ChatMessageType.welcome,
      ),
      ChatMessage(
        text:
            '¿En qué puedo ayudarte hoy? Puedes preguntarme sobre enfermedades, plagas, manejo de cultivos o cualquier consulta agrícola.',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: ChatMessageType.text,
      ),
    ]);

    // Agregar opciones rápidas
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.quickOptions,
              quickOptions: [
                'Diagnosticar enfermedad 🔍',
                'Identificar plaga 🐛',
                'Consulta de manejo 🌿',
                'Ver historial 📋',
              ],
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(),
      body: BlocListener<ConversationBloc, ConversationState>(
        listener: (context, state) {
          // Manejar estados progresivos
          if (state.status == ConversationStatus.analyzing ||
              state.status == ConversationStatus.searchingTreatment ||
              state.status == ConversationStatus.validating ||
              state.status == ConversationStatus.processing) {
            if (state.progressMessage != null) {
              setState(() {
                // Remover mensaje de progreso anterior si existe
                _messages.removeWhere((msg) => msg.messageType == ChatMessageType.progress);
                _messages.add(
                  ChatMessage(
                    text: state.progressMessage!,
                    isUser: false,
                    timestamp: DateTime.now(),
                    messageType: ChatMessageType.progress,
                  ),
                );
              });
              _scrollToBottom();
            }
          }

          // Manejar respuesta final
          if (state.status == ConversationStatus.success && state.lastResponse != null) {
            setState(() {
              // Remover mensajes de progreso e indicador de procesamiento de imagen
              _messages.removeWhere(
                (msg) =>
                    msg.messageType == ChatMessageType.progress || msg.messageType == ChatMessageType.imageProcessing,
              );

              // Check if response has vision result with multiple detections
              if (state.lastResponse!.visionResult != null &&
                  state.lastResponse!.visionResult!.metadata != null &&
                  state.lastResponse!.visionResult!.metadata!['all_detections'] != null) {
                _messages.add(
                  ChatMessage(
                    text: state.lastResponse!.responseText,
                    isUser: false,
                    timestamp: DateTime.now(),
                    messageType: ChatMessageType.multipleDetections,
                    visionResult: state.lastResponse!.visionResult,
                  ),
                );
              } else {
                _messages.add(
                  ChatMessage(
                    text: state.lastResponse!.responseText,
                    isUser: false,
                    timestamp: DateTime.now(),
                    messageType: ChatMessageType.text,
                  ),
                );
              }
            });
            _scrollToBottom();
          }

          // Manejar errores
          if (state.status == ConversationStatus.error) {
            setState(() {
              // Remover mensajes de progreso e indicador de procesamiento de imagen
              _messages.removeWhere(
                (msg) =>
                    msg.messageType == ChatMessageType.progress || msg.messageType == ChatMessageType.imageProcessing,
              );
              _messages.add(
                ChatMessage(
                  text: '❌ Error: ${state.errorMessage ?? "Ocurrió un error inesperado"}',
                  isUser: false,
                  timestamp: DateTime.now(),
                  messageType: ChatMessageType.text,
                ),
              );
            });
            _scrollToBottom();
          }
        },
        child: Column(
          children: [
            Expanded(child: _buildChatArea()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16,
            child: Icon(Icons.agriculture, color: AppTheme.primaryColor, size: 16),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asistente Metriagro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('En línea', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
      actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: _showMenuOptions)],
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      // Performance optimizations
      cacheExtent: 1000, // Pre-render items
      addAutomaticKeepAlives: false, // Don't keep off-screen items alive
      addRepaintBoundaries: true, // Isolate repaints
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    switch (message.messageType) {
      case ChatMessageType.welcome:
        return _buildWelcomeMessage(message);
      case ChatMessageType.quickOptions:
        return _buildQuickOptionsMessage(message);
      case ChatMessageType.media:
        return _buildMediaMessage(message);
      case ChatMessageType.response:
        return _buildResponseMessage(message);
      case ChatMessageType.progress:
        return _buildProgressMessage(message);
      case ChatMessageType.text:
        return _buildTextMessage(message);
      case ChatMessageType.imageProcessing:
        return _buildImageProcessingMessage(message);
      case ChatMessageType.multipleDetections:
        return _buildMultipleDetectionsMessage(message);
    }
  }

  Widget _buildTextMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 16,
              child: Icon(Icons.agriculture, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(color: message.isUser ? Colors.white70 : Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 16,
            child: Icon(Icons.agriculture, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(message.text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageProcessingMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 20,
            child: Icon(Icons.agriculture, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔍 Analizando imagen de cacao...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ejecutando modelo de IA para detectar enfermedades',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.3),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mostrar imagen que se está procesando
                  if (message.imageData != null) ...[
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          message.imageData!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          cacheHeight: 120,
                          filterQuality: FilterQuality.low,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 150),
                              child: child,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Indicador de progreso con pasos
                  _buildProcessingSteps(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Procesando...',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildAnimatedStepIndicator('Optimizando', true),
            _buildAnimatedStepIndicator('Ejecutando ML', true),
            _buildAnimatedStepIndicator('Generando', true),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedStepIndicator(String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            boxShadow: isActive
                ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)]
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.primaryColor : Colors.grey[500],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleDetectionsMessage(ChatMessage message) {
    final visionResult = message.visionResult!;
    final allDetections = visionResult.metadata?['all_detections'] as List<dynamic>? ?? [];
    final totalDetections = allDetections.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 20,
            child: Icon(Icons.agriculture, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with detection count
                  Row(
                    children: [
                      Icon(Icons.analytics, color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔍 Análisis completado',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Se encontraron $totalDetections detecciones',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Main response text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detection results
                  Text(
                    'Resultados de detección:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // List of detections
                  ...allDetections.take(5).map((detection) => _buildDetectionItem(detection)).toList(),

                  if (totalDetections > 5) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${totalDetections - 5} detecciones adicionales',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Confidence summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confianza promedio: ${(visionResult.confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 13, color: Colors.blue[800], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionItem(dynamic detection) {
    final diseaseName = detection['diseaseName'] as String? ?? 'Desconocido';
    final confidence = (detection['confidence'] as num?)?.toDouble() ?? 0.0;
    final confidencePercent = (confidence * 100).toStringAsFixed(1);

    Color confidenceColor;
    if (confidence >= 0.8) {
      confidenceColor = Colors.green;
    } else if (confidence >= 0.6) {
      confidenceColor = Colors.orange;
    } else {
      confidenceColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: confidenceColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confianza: $confidencePercent%',
                  style: TextStyle(fontSize: 12, color: confidenceColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: confidenceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              confidencePercent,
              style: TextStyle(fontSize: 11, color: confidenceColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.agriculture, color: AppTheme.primaryColor, size: 40),
          const SizedBox(height: 12),
          Text(
            message.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildQuickOptionsMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 16,
                child: Icon(Icons.agriculture, color: Colors.white, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                'Opciones rápidas:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.quickOptions!.map((option) => _buildQuickOptionChip(option)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptionChip(String option) {
    return GestureDetector(
      onTap: () => _handleQuickOption(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          option,
          style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildMediaMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 16,
              child: Icon(Icons.agriculture, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: message.isUser ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar imagen si hay datos de imagen
                if (message.imageData != null) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.memory(
                      message.imageData!,
                      width: 250,
                      height: 200,
                      fit: BoxFit.cover,
                      cacheWidth: 250,
                      cacheHeight: 200,
                      filterQuality: FilterQuality.low, // Faster rendering
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: child,
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Fallback si no hay datos de imagen
                  Container(
                    width: 250,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Icon(
                        message.mediaType == 'image' ? Icons.image : Icons.videocam,
                        color: Colors.grey[500],
                        size: 40,
                      ),
                    ),
                  ),
                ],
                // Texto descriptivo
                if (message.text.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageData != null) ...[
                          Text(
                            'Descripción:',
                            style: TextStyle(
                              color: message.isUser ? Colors.white70 : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 16,
                child: Icon(Icons.agriculture, color: Colors.white, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                'Análisis completado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResponseSection('Respuesta Natural', message.naturalResponse ?? '', Icons.chat_bubble_outline),
          const SizedBox(height: 16),
          _buildResponseSection('Información Técnica', message.technicalResponse ?? '', Icons.science),
          const SizedBox(height: 16),
          _buildResponseSection('Referencias', message.references ?? '', Icons.library_books),
          const SizedBox(height: 16),
          _buildFeedbackButtons(message),
        ],
      ),
    );
  }

  Widget _buildResponseSection(String title, String content, IconData icon) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            content.isNotEmpty ? content : 'Información no disponible',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackButtons(ChatMessage message) {
    return Row(
      children: [
        const Text('¿Te fue útil?', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _provideFeedback(message, true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: message.wasHelpful == true ? Colors.green : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thumb_up, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Sí',
                  style: TextStyle(
                    fontSize: 11,
                    color: message.wasHelpful == true ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _provideFeedback(message, false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: message.wasHelpful == false ? Colors.red : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thumb_down, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'No',
                  style: TextStyle(
                    fontSize: 11,
                    color: message.wasHelpful == false ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              onPressed: () => _showMediaOptions(),
            ),
            Builder(
              builder: (context) {
                return BlocBuilder<ConversationBloc, ConversationState>(
                  buildWhen: (prev, curr) => prev.isListening != curr.isListening,
                  builder: (context, state) {
                    final isListening = state.isListening;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isListening
                            ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 16)]
                            : null,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.mic, color: isListening ? Colors.red : AppTheme.primaryColor),
                        onPressed: () => context.read<ConversationBloc>().add(
                          const ConversationListenToggled(expectedCropType: CropType.cacao),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Escribe tu consulta...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: _sendTextMessage,
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<ConversationBloc, ConversationState>(
              builder: (context, state) {
                final isProcessing = state.status == ConversationStatus.processing;
                return GestureDetector(
                  onTap: isProcessing
                      ? null
                      : () {
                          final text = _textController.text;
                          if (text.trim().isEmpty) return;
                          setState(() {
                            _messages.add(
                              ChatMessage(
                                text: text,
                                isUser: true,
                                timestamp: DateTime.now(),
                                messageType: ChatMessageType.text,
                              ),
                            );
                          });
                          _textController.clear();
                          _scrollToBottom();
                          context.read<ConversationBloc>().add(
                            ConversationSubmitted(
                              ConversationRequest(
                                textInput: text,
                                inputType: InputType.text,
                                expectedCropType: CropType.cacao,
                              ),
                            ),
                          );
                        },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleQuickOption(String option) {
    setState(() {
      _messages.add(
        ChatMessage(text: option, isUser: true, timestamp: DateTime.now(), messageType: ChatMessageType.text),
      );
    });

    _scrollToBottom();

    // Simular respuesta del asistente
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        if (option.contains('Diagnosticar') || option.contains('Identificar')) {
          _messages.add(
            ChatMessage(
              text: 'Para ayudarte mejor, ¿puedes compartir una foto de tu cultivo?',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.text,
            ),
          );
        } else if (option.contains('historial')) {
          _showConversationHistory();
        } else {
          _messages.add(
            ChatMessage(
              text:
                  'Perfecto, estoy aquí para ayudarte con el manejo de tu cultivo. ¿Qué específicamente necesitas saber?',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.text,
            ),
          );
        }
      });
      _scrollToBottom();
    });
  }

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now(), messageType: ChatMessageType.text),
      );
    });

    _textController.clear();
    _scrollToBottom();

    // Simular respuesta del asistente
    _simulateAssistantResponse(text);
  }

  void _simulateAssistantResponse(String userMessage) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        if (userMessage.toLowerCase().contains('enfermedad') ||
            userMessage.toLowerCase().contains('plaga') ||
            userMessage.toLowerCase().contains('problema')) {
          // Respuesta completa con análisis
          _messages.add(
            ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.response,
              naturalResponse:
                  'Basándome en tu descripción, parece que tu cultivo podría tener síntomas de roya. Es una enfermedad fúngica común que se manifiesta con manchas anaranjadas en las hojas.',
              technicalResponse:
                  'Diagnóstico: Puccinia spp. (Roya)\nTratamiento: Fungicidas sistémicos (Propiconazol 250g/L)\nDosis: 1.5-2.0 L/ha\nFrecuencia: Cada 14-21 días',
              references:
                  '• Manual de Enfermedades Fúngicas - INTA 2023\n• Guía de Manejo Integrado - FAO\n• Protocolo de Aplicación - SENASA',
            ),
          );
        } else {
          // Respuesta simple
          _messages.add(
            ChatMessage(
              text:
                  'Entiendo tu consulta. Para darte una respuesta más precisa, ¿podrías compartir más detalles o una imagen de tu cultivo?',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.text,
            ),
          );
        }
      });
      _scrollToBottom();
    });
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Compartir imagen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption('Cámara', Icons.camera_alt, () => _captureMedia('camera')),
                _buildMediaOption('Galería', Icons.photo_library, () => _captureMedia('gallery')),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _captureMedia(String type) async {
    // Capturar el bloc antes de cerrar el modal para no perder el scope del provider
    final conversationBloc = context.read<ConversationBloc>();
    Navigator.pop(context);

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: type == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800, // Limit image size
        maxHeight: 600,
        imageQuality: 85, // Compress image
      );
      if (picked == null) return;

      // Show loading indicator while processing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Process image in background to avoid blocking main thread
      final bytes = await compute(_processImage, picked.path);

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar modal multimodal inmediatamente después de capturar
      if (mounted) {
        _showMultimodalCaptureModal(bytes, conversationBloc);
      }
    } catch (e) {
      // Hide loading indicator on error
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error procesando imagen: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // Static method for background image processing
  static Future<Uint8List> _processImage(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();

      // Optimize image size if it's too large
      if (bytes.length > 1024 * 1024) {
        // If larger than 1MB
        // Decode and re-encode with compression
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          // Resize if too large
          img.Image resized = decoded;
          if (decoded.width > 800 || decoded.height > 600) {
            resized = img.copyResize(decoded, width: 800, height: 600, interpolation: img.Interpolation.linear);
          }

          // Re-encode with compression
          final compressedBytes = img.encodeJpg(resized, quality: 85);
          return Uint8List.fromList(compressedBytes);
        }
      }

      return bytes;
    } catch (e) {
      print('[ConversationalConsultationPage] Error processing image: $e');
      // Return original bytes if processing fails
      final file = File(path);
      return await file.readAsBytes();
    }
  }

  void _showMultimodalCaptureModal(Uint8List imageBytes, ConversationBloc conversationBloc) {
    final TextEditingController textController = TextEditingController();
    bool isRecording = false;
    final WhisperTranscriber transcriber = SpeechToTextWhisperTranscriber();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Completa tu consulta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),

              // Image preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    cacheWidth: 400,
                    cacheHeight: 200,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Text input with audio button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe qué ves o qué te preocupa...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.text_fields),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (isRecording) {
                          // Detener grabación y transcribir
                          setModalState(() {
                            isRecording = false;
                          });

                          try {
                            // Inicializar transcriber si no está inicializado
                            await transcriber.initialize();

                            // Simular datos de audio (en implementación real, estos vendrían del micrófono)
                            final audioData = Uint8List.fromList([1, 2, 3, 4, 5]); // Datos simulados

                            // Mostrar indicador de transcripción
                            setModalState(() {
                              textController.text = "Transcribiendo audio...";
                            });

                            // Transcribir con Whisper
                            final result = await transcriber.transcribe(audioData);

                            setModalState(() {
                              textController.text = result;
                            });
                          } catch (e) {
                            setModalState(() {
                              textController.text = "Error en transcripción: $e";
                            });
                          }
                        } else {
                          // Iniciar grabación
                          setModalState(() {
                            isRecording = true;
                            textController.clear();
                          });
                          // Aquí se iniciaría la grabación de audio real
                        }
                      },
                      icon: Icon(isRecording ? Icons.stop : Icons.mic),
                      label: Text(isRecording ? 'Detener' : 'Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecording ? Colors.red : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendMultimodalRequest(imageBytes, textController.text.trim(), null, conversationBloc);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enviar consulta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMultimodalRequest(
    Uint8List imageBytes,
    String text,
    CropType? cropType,
    ConversationBloc conversationBloc,
  ) {
    // Mostrar mensaje del usuario inmediatamente
    setState(() {
      _messages.add(
        ChatMessage(
          text: text.isNotEmpty ? text : '📸 Imagen compartida',
          isUser: true,
          timestamp: DateTime.now(),
          messageType: ChatMessageType.media,
          mediaType: 'image',
          imageData: imageBytes,
        ),
      );
    });
    _scrollToBottom();

    // Mostrar indicador de procesamiento inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Procesando imagen...',
              isUser: false,
              timestamp: DateTime.now(),
              messageType: ChatMessageType.imageProcessing,
              imageData: imageBytes,
            ),
          );
        });
        _scrollToBottom();
      }
    });

    // Send request
    if (mounted) {
      conversationBloc.add(
        ConversationSubmitted(
          ConversationRequest(
            imageData: imageBytes,
            textInput: text.isNotEmpty ? text : null,
            inputType: text.isNotEmpty ? InputType.multimodal : InputType.image,
            expectedCropType: CropType.cacao, // Default to cacao as specified
          ),
        ),
      );
    }
  }

  // image analysis now dispatched to ConversationBloc

  // mic handled by ConversationBloc (tap-to-talk)

  void _provideFeedback(ChatMessage message, bool helpful) {
    setState(() {
      message.wasHelpful = helpful;
    });

    setState(() {
      _messages.add(
        ChatMessage(
          text: helpful
              ? 'Gracias por tu feedback positivo! ¿Hay algo más en lo que pueda ayudarte?'
              : 'Lamento que no haya sido útil. ¿Puedes decirme qué información te faltó?',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: ChatMessageType.text,
        ),
      );
    });
    _scrollToBottom();
  }

  void _showConversationHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ConversationHistoryPage()));
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Menú de Opciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.history, color: AppTheme.primaryColor),
              title: const Text('Ver historial'),
              onTap: () {
                Navigator.pop(context);
                _showConversationHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              title: const Text('Nueva conversación'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                });
                _initializeChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryColor),
              title: const Text('Compartir conversación'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar compartir
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    // Debounce scroll operations to prevent excessive calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients && mounted) {
        // Use a more efficient scroll method
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        } catch (e) {
          // Ignore scroll errors to prevent crashes
          print('[ConversationalConsultationPage] Scroll error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

// Modelos de datos
enum ChatMessageType { text, welcome, quickOptions, media, response, progress, imageProcessing, multipleDetections }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType messageType;
  final List<String>? quickOptions;
  final String? mediaType;
  final Uint8List? imageData;
  final String? naturalResponse;
  final String? technicalResponse;
  final String? references;
  final VisionResult? visionResult;
  bool? wasHelpful;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.quickOptions,
    this.mediaType,
    this.imageData,
    this.naturalResponse,
    this.technicalResponse,
    this.references,
    this.visionResult,
    this.wasHelpful,
  });
}

// Página de historial de conversaciones
class ConversationHistoryPage extends StatelessWidget {
  const ConversationHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Historial de Conversaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
      body: _HistoryList(),
    );
  }

  static Widget _buildConversationCardStatic({
    required String title,
    required String preview,
    required String date,
    required int messageCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                radius: 16,
                child: const Icon(Icons.chat, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$messageCount mensajes',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatefulWidget {
  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  late final HistoryStorage _history;
  List<ConversationSummary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _history = sl<HistoryStorage>();
    _load();
  }

  Future<void> _load() async {
    final list = await _history.listConversations();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Aún no hay conversaciones'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ConversationHistoryPage._buildConversationCardStatic(
          title: item.title,
          preview: 'Actualizada: ${item.updatedAt}',
          date: '${item.updatedAt.hour.toString().padLeft(2, '0')}:${item.updatedAt.minute.toString().padLeft(2, '0')}',
          messageCount: item.messageCount,
        );
      },
    );
  }
}

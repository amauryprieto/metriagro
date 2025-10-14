import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metriagro/core/theme/app_theme.dart';
import 'package:metriagro/core/di/injection_container.dart';
import '../../../conversation/presentation/bloc/conversation_bloc.dart';
import '../../../conversation/domain/conversation_engine.dart';
import '../../../../shared/models/conversation_models.dart';
import '../../../../shared/services/tts_speaker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../shared/services/history_storage.dart';

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
    return BlocProvider(
      create: (_) =>
          ConversationBloc(engine: sl<ConversationEngine>(), tts: sl<TtsSpeaker>())..add(const ConversationStarted()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: _buildAppBar(),
        body: BlocListener<ConversationBloc, ConversationState>(
          listener: (context, state) {
            if (state.status == ConversationStatus.success && state.lastResponse != null) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: state.lastResponse!.responseText,
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
      case ChatMessageType.text:
        return _buildTextMessage(message);
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
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Icon(
                      message.mediaType == 'image' ? Icons.image : Icons.videocam,
                      color: Colors.grey[500],
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.text.isNotEmpty ? message.text : 'Archivo multimedia',
                  style: TextStyle(color: message.isUser ? Colors.white : AppTheme.textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
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
              text: 'Para ayudarte mejor, ¿puedes compartir una foto o video de tu cultivo?',
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
            const Text('Compartir multimedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption('Cámara', Icons.camera_alt, () => _captureMedia('camera')),
                _buildMediaOption('Galería', Icons.photo_library, () => _captureMedia('gallery')),
                _buildMediaOption('Video', Icons.videocam, () => _captureMedia('video')),
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
    Navigator.pop(context);
    if (type == 'video') {
      // No soportado en MVP
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video no soportado en este MVP')));
      return;
    }
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: type == 'camera' ? ImageSource.camera : ImageSource.gallery);
    if (picked == null) return;
    final Uint8List bytes = await picked.readAsBytes();

    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Imagen compartida',
          isUser: true,
          timestamp: DateTime.now(),
          messageType: ChatMessageType.media,
          mediaType: 'image',
        ),
      );
    });
    _scrollToBottom();

    // Enviar imagen al motor conversacional (offline/online)
    if (mounted) {
      context.read<ConversationBloc>().add(
        ConversationSubmitted(
          ConversationRequest(imageData: bytes, inputType: InputType.image, expectedCropType: CropType.cacao),
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
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

// Modelos de datos
enum ChatMessageType { text, welcome, quickOptions, media, response }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType messageType;
  final List<String>? quickOptions;
  final String? mediaType;
  final String? naturalResponse;
  final String? technicalResponse;
  final String? references;
  bool? wasHelpful;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.quickOptions,
    this.mediaType,
    this.naturalResponse,
    this.technicalResponse,
    this.references,
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

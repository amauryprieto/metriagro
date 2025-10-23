import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../shared/models/conversation_models.dart';
import '../../../conversation/domain/conversation_engine.dart';
import '../../../../shared/services/tts_speaker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../shared/services/history_storage.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ConversationEngine _engine;
  final TtsSpeaker _tts;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final HistoryStorage _history;
  String? _conversationId;

  ConversationBloc({required ConversationEngine engine, required TtsSpeaker tts, HistoryStorage? history})
    : _engine = engine,
      _tts = tts,
      _history = history ?? SqliteHistoryStorage(),
      super(const ConversationState.initial()) {
    on<ConversationStarted>(_onStarted);
    on<ConversationSubmitted>(_onSubmitted);
    on<ConversationListenToggled>(_onListenToggled);
  }

  Future<void> _onStarted(ConversationStarted event, Emitter<ConversationState> emit) async {
    emit(state.copyWith(status: ConversationStatus.initializing));
    await _engine.initialize();
    await _history.initialize();
    _conversationId ??= await _history.createConversation(title: 'Nueva conversación');
    final available = await _engine.isAvailable();
    emit(state.copyWith(status: available ? ConversationStatus.ready : ConversationStatus.error));
  }

  Future<void> _onSubmitted(ConversationSubmitted event, Emitter<ConversationState> emit) async {
    print('[ConversationBloc] Starting conversation submission');
    print('[ConversationBloc] Request type: ${event.request.inputType}');
    print('[ConversationBloc] Has image: ${event.request.hasImage}');
    print('[ConversationBloc] Has text: ${event.request.hasText}');
    print('[ConversationBloc] Has audio: ${event.request.hasAudio}');
    print('[ConversationBloc] Expected crop type: ${event.request.expectedCropType}');

    emit(state.copyWith(status: ConversationStatus.processing, progressMessage: 'Iniciando análisis...'));
    try {
      // Guardar mensaje del usuario
      final cid = _conversationId ??= await _history.createConversation(title: 'Nueva conversación');
      final userText = event.request.textInput ?? (event.request.imageData != null ? '[Imagen enviada]' : '[Entrada]');
      await _history.addMessage(
        conversationId: cid,
        isUser: true,
        text: userText,
        timestamp: DateTime.now(),
        type: event.request.hasImage ? 'media' : 'text',
      );

      // 1. Transcribir audio si existe
      if (event.request.hasAudio) {
        print('[ConversationBloc] Processing audio transcription');
        emit(state.copyWith(status: ConversationStatus.processing, progressMessage: '🔄 Transcribiendo audio...'));
      }

      // 2. Analizar imagen
      if (event.request.hasImage) {
        print('[ConversationBloc] Processing image analysis');
        emit(state.copyWith(status: ConversationStatus.analyzing, progressMessage: '🔍 Analizando tu foto...'));
      }

      // 3. Buscar tratamiento
      emit(
        state.copyWith(status: ConversationStatus.searchingTreatment, progressMessage: '📚 Buscando tratamiento...'),
      );

      // 4. Validar resultados
      emit(state.copyWith(status: ConversationStatus.validating, progressMessage: '✅ Validando resultados...'));

      print('[ConversationBloc] Calling conversation engine...');
      final response = await _engine.processConversation(event.request);
      print('[ConversationBloc] Conversation engine response received');
      emit(state.copyWith(status: ConversationStatus.success, lastResponse: response));

      // Guardar respuesta del asistente
      await _history.addMessage(
        conversationId: cid,
        isUser: false,
        text: response.responseText,
        timestamp: response.timestamp,
        type: 'text',
      );
      await _tts.speak(response.responseText);
    } catch (e, stackTrace) {
      print('[ConversationBloc] Error occurred: $e');
      print('[ConversationBloc] Stack trace: $stackTrace');
      emit(state.copyWith(status: ConversationStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onListenToggled(ConversationListenToggled event, Emitter<ConversationState> emit) async {
    if (!_speech.isAvailable) {
      await _speech.initialize();
    }
    if (_speech.isListening) {
      await _speech.stop();
      emit(state.copyWith(isListening: false));
    } else {
      emit(state.copyWith(isListening: true));
      await _speech.listen(
        localeId: 'es_CO',
        onResult: (res) async {
          final text = res.recognizedWords;
          if (text.isNotEmpty && res.finalResult) {
            final request = ConversationRequest(
              textInput: text,
              inputType: InputType.text,
              expectedCropType: event.expectedCropType,
            );
            add(ConversationSubmitted(request));
            emit(state.copyWith(isListening: false));
          }
        },
      );
    }
  }
}

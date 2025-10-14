import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class AudioTranscriber {
  Future<void> initialize();
  Future<String> transcribe(Uint8List audioData);
  Future<void> dispose();
}

class SpeechToTextTranscriber implements AudioTranscriber {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  @override
  Future<void> initialize() async {
    _available = await _speech.initialize();
  }

  @override
  Future<String> transcribe(Uint8List audioData) async {
    // Nota: speech_to_text trabaja con audio del micrófono en tiempo real.
    // Para una primera versión offline, devolvemos un stub si no está disponible.
    if (!_available) {
      return '';
    }
    // Integración de audioData no está soportada directamente por speech_to_text.
    // La UI usará el micrófono en vivo; este método actúa como placeholder.
    return '';
  }

  @override
  Future<void> dispose() async {
    await _speech.stop();
  }
}


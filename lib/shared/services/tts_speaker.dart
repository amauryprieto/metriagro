import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsSpeaker {
  Future<void> initialize();
  Future<void> speak(String text, {String languageCode});
  Future<void> stop();
}

class FlutterTtsSpeaker implements TtsSpeaker {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('es-CO');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  @override
  Future<void> speak(String text, {String languageCode = 'es-CO'}) async {
    if (!_initialized) await initialize();
    await _tts.setLanguage(languageCode);
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

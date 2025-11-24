import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/services/text_embedding_service.dart';

/// DistilUSE-base-multilingual embedding service using TFLite.
///
/// Model: distiluse-base-multilingual-cased-v2
/// - Embedding dimension: 512
/// - Max sequence length: 128
/// - Supports 50+ languages including Spanish
class DistilUseEmbeddingService implements TextEmbeddingService {
  static const String _modelPath = 'assets/models/distiluse_base.tflite';
  static const String _vocabPath = 'assets/models/vocab.txt';
  static const int _embeddingDim = 512;
  static const int _maxSeqLength = 128;

  Interpreter? _interpreter;
  late SimpleTokenizer _tokenizer;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  int get embeddingDimension => _embeddingDim;

  @override
  String get modelName => 'DistilUSE-base-multilingual-cased-v2';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Configure interpreter
      _interpreter!.allocateTensors();

      // Load tokenizer vocabulary
      final vocabData = await rootBundle.loadString(_vocabPath);
      _tokenizer = SimpleTokenizer(vocabData.split('\n'));

      _initialized = true;
      print('[DistilUseEmbeddingService] Initialized with $_embeddingDim dimensions');
    } catch (e) {
      print('[DistilUseEmbeddingService] Error initializing: $e');
      rethrow;
    }
  }

  @override
  Future<Float32List> encode(String text) async {
    if (!_initialized) {
      await initialize();
    }

    // Tokenize input
    final tokenized = _tokenizer.tokenize(text, maxLength: _maxSeqLength);

    // Prepare input tensors [1, 128]
    final inputIds = List<List<int>>.generate(
      1,
      (_) => tokenized.inputIds.toList(),
    );
    final attentionMask = List<List<int>>.generate(
      1,
      (_) => tokenized.attentionMask.toList(),
    );

    // Prepare output tensor [1, 512]
    final output = List<List<double>>.generate(
      1,
      (_) => List<double>.filled(_embeddingDim, 0.0),
    );

    // Run inference
    _interpreter!.runForMultipleInputs(
      [inputIds, attentionMask],
      {0: output},
    );

    // Extract and normalize embedding
    final embedding = Float32List.fromList(
      output[0].map((e) => e.toDouble()).toList(),
    );

    return _normalizeL2(embedding);
  }

  @override
  Future<List<Float32List>> encodeBatch(List<String> texts) async {
    final results = <Float32List>[];
    for (final text in texts) {
      results.add(await encode(text));
    }
    return results;
  }

  /// L2 normalize the embedding vector
  Float32List _normalizeL2(Float32List vector) {
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = sqrt(norm);

    if (norm > 0) {
      for (var i = 0; i < vector.length; i++) {
        vector[i] = vector[i] / norm;
      }
    }

    return vector;
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
    print('[DistilUseEmbeddingService] Disposed');
  }
}

/// Simple tokenizer for transformer models.
/// This is a basic implementation - for production, use a proper
/// SentencePiece or WordPiece tokenizer.
class SimpleTokenizer {
  final List<String> _vocab;
  final Map<String, int> _vocabIndex;

  static const int _padTokenId = 0;
  static const int _unkTokenId = 100;
  static const int _clsTokenId = 101;
  static const int _sepTokenId = 102;

  SimpleTokenizer(List<String> vocab)
      : _vocab = vocab,
        _vocabIndex = {
          for (var i = 0; i < vocab.length; i++) vocab[i].trim(): i
        };

  TokenizedInput tokenize(String text, {int maxLength = 128}) {
    // Normalize text
    text = text.toLowerCase().trim();

    // Basic tokenization by splitting on whitespace and punctuation
    final words = _splitText(text);

    // Convert to token IDs
    final tokens = <int>[_clsTokenId];

    for (final word in words) {
      if (tokens.length >= maxLength - 1) break;

      final tokenId = _vocabIndex[word];
      if (tokenId != null) {
        tokens.add(tokenId);
      } else {
        // Try subword tokenization
        final subwords = _tokenizeSubwords(word);
        for (final subword in subwords) {
          if (tokens.length >= maxLength - 1) break;
          tokens.add(subword);
        }
      }
    }

    tokens.add(_sepTokenId);

    // Create attention mask
    final attentionMask = List<int>.filled(maxLength, 0);
    for (var i = 0; i < tokens.length; i++) {
      attentionMask[i] = 1;
    }

    // Pad tokens
    while (tokens.length < maxLength) {
      tokens.add(_padTokenId);
    }

    return TokenizedInput(
      inputIds: Int32List.fromList(tokens),
      attentionMask: Int32List.fromList(attentionMask),
      length: tokens.length,
    );
  }

  List<String> _splitText(String text) {
    // Split on whitespace and common punctuation
    final parts = <String>[];
    final buffer = StringBuffer();

    for (final char in text.runes) {
      final c = String.fromCharCode(char);
      if (c == ' ' || c == '\t' || c == '\n') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else if ('.,;:!?()[]{}"\'-'.contains(c)) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
        parts.add(c);
      } else {
        buffer.write(c);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  List<int> _tokenizeSubwords(String word) {
    final subwords = <int>[];
    var remaining = word;
    var isFirst = true;

    while (remaining.isNotEmpty && subwords.length < 10) {
      String? longestMatch;
      int longestLength = 0;

      // Try to find the longest matching subword
      for (var end = remaining.length; end > 0; end--) {
        final candidate = isFirst
            ? remaining.substring(0, end)
            : '##${remaining.substring(0, end)}';

        if (_vocabIndex.containsKey(candidate)) {
          longestMatch = candidate;
          longestLength = end;
          break;
        }
      }

      if (longestMatch != null) {
        subwords.add(_vocabIndex[longestMatch]!);
        remaining = remaining.substring(longestLength);
        isFirst = false;
      } else {
        // Unknown token
        subwords.add(_unkTokenId);
        break;
      }
    }

    return subwords;
  }
}

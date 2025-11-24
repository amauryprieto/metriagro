import 'dart:typed_data';

/// Interface for text embedding services.
/// Converts text into dense vector representations for semantic search.
abstract class TextEmbeddingService {
  /// Initialize the embedding model and tokenizer
  Future<void> initialize();

  /// Encode a single text into an embedding vector
  Future<Float32List> encode(String text);

  /// Encode multiple texts into embedding vectors
  Future<List<Float32List>> encodeBatch(List<String> texts);

  /// Dispose resources
  Future<void> dispose();

  /// Whether the service is initialized and ready
  bool get isInitialized;

  /// Dimension of the embedding vectors
  int get embeddingDimension;

  /// Name of the model for debugging
  String get modelName;
}

/// Result of tokenization
class TokenizedInput {
  final Int32List inputIds;
  final Int32List attentionMask;
  final int length;

  TokenizedInput({
    required this.inputIds,
    required this.attentionMask,
    required this.length,
  });
}

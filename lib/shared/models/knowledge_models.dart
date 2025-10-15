import 'dart:typed_data';

/// Documento/chunk de conocimiento indexado
class DocumentChunk {
  final String id;
  final String title;
  final String? sectionPath;
  final String category; // enfermedad|plaga|práctica|seguridad|general
  final String crop; // cacao
  final String content;
  final int? tokensCount;
  final Uint8List? embedding; // float32 serializada
  final double? embeddingNorm;
  final DateTime updatedAt;

  DocumentChunk({
    required this.id,
    required this.title,
    required this.sectionPath,
    required this.category,
    required this.crop,
    required this.content,
    required this.tokensCount,
    required this.embedding,
    required this.embeddingNorm,
    required this.updatedAt,
  });
}

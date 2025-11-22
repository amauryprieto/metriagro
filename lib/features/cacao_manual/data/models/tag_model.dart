import '../../domain/entities/tag.dart';

class TagModel extends Tag {
  const TagModel({
    required super.id,
    required super.name,
  });

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
    };
  }

  factory TagModel.fromEntity(Tag entity) {
    return TagModel(
      id: entity.id,
      name: entity.name,
    );
  }
}

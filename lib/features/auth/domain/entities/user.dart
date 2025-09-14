import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({required this.id, required this.email, this.name, this.photoUrl, this.createdAt, this.updatedAt});

  @override
  List<Object?> get props => [id, email, name, photoUrl, createdAt, updatedAt];
}

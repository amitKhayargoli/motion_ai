import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String email;
  final String? username;
  final String? password;
  final String? profilePicture;
  final DateTime? createdAt;

  AuthApiModel({
    this.id,
    required this.email,
    this.password,
    this.username,
    this.profilePicture,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {"email": email, "password": password, "username": username};
  }

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] as String?,
      email: json['email'] as String,
      username: json['username'] as String?,
      password: json['passwordHash'] as String?,
      profilePicture: json['profilePicture'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(
      userId: id,
      email: email,
      password: password,
      username: username,
      profilePicture: profilePicture,
      createdAt: createdAt,
    );
  }

  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      id: entity.userId,
      email: entity.email,
      password: entity.password,
      username: entity.username ?? entity.email.split('@').first,
      profilePicture: entity.profilePicture,
      createdAt: entity.createdAt,
    );
  }
}

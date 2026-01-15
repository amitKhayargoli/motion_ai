import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';

class AuthApiModel {
  final String? id;
  final String email;
  final String? username;
  final String? password;

  AuthApiModel({this.id, required this.email, this.password, this.username});

  Map<String, dynamic> toJson() {
    return {"email": email, "password": password, "username": username};
  }

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      password: json['passwordHash'] as String?,
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(email: email, password: password);
  }

  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      email: entity.email,
      password: entity.password,
      username: entity.email.split('@').first,
    );
  }
}

import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? userId;
  final String email;
  final String? password;
  final DateTime? createdAt;

  const AuthEntity({
    this.userId,
    required this.email,
    required this.password,
    this.createdAt,
  });

  @override
  List<Object?> get props => [userId, email, password, createdAt];
}

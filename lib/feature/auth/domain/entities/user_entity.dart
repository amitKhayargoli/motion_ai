import 'package:equatable/equatable.dart';

enum userRole { admin, user }

class UserEntity extends Equatable {
  final String? userId;
  final String email;
  final String password;
  final userRole? role;
  final DateTime? createdAt;

  const UserEntity({
    this.userId,
    required this.email,
    required this.password,
    this.role,
    this.createdAt,
  });

  @override
  List<Object?> get props => [userId, email, password, role, createdAt];
}

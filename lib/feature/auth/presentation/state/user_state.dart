import 'package:equatable/equatable.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';

enum UserStatus { initial, loading, loaded, error, created, updated, deleted }

class UserState extends Equatable {
  final UserStatus status;
  final List<UserEntity> users;
  final String? errorMessage;

  const UserState({
    this.status = UserStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  UserState copyWith({
    UserStatus? status,
    List<UserEntity>? users,
    String? errorMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, errorMessage];
}

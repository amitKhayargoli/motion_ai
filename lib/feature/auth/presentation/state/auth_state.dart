import 'package:equatable/equatable.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  registered,
  error,
  loaded,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthEntity? user;
  final String? errorMessage;
  final String? uploadPhotoName;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.uploadPhotoName,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthEntity? user,
    Object? errorMessage = _noChange,
    String? uploadPhotoName,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
      uploadPhotoName: uploadPhotoName ?? this.uploadPhotoName,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, uploadPhotoName];
}

const _noChange = Object();

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/auth/data/repositories/auth_repository.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/auth_repository.dart';

class UpdateUserUsecaseParams extends Equatable {
  final String? userId;
  final String email;
  final String? password;
  final String? username;
  final DateTime? createdAt;

  const UpdateUserUsecaseParams({
    this.userId,
    required this.email,
    this.password,
    this.username,
    this.createdAt,
  });

  @override
  List<Object?> get props => [userId, email, password, username, createdAt];
}

// Create Provider
final updateUserUsecaseProvider = Provider<UpdateUserUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return UpdateUserUsecase(authRepository);
});

class UpdateUserUsecase
    implements UseCaseWithParams<void, UpdateUserUsecaseParams> {
  final IAuthRepository _userRepository;
  UpdateUserUsecase(this._userRepository);

  @override
  Future<Either<Failure, void>> call(UpdateUserUsecaseParams params) {
    final user = AuthEntity(
      userId: params.userId,
      email: params.email,
      password: params.password,
      username: params.username,
    );
    return _userRepository.updateUser(user);
  }
}

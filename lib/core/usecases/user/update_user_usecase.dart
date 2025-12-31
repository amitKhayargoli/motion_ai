import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/user_repository.dart';

class UpdateUserUsecaseParams extends Equatable {
  final String? userId;
  final String email;
  final String password;
  final userRole? role;
  final DateTime? createdAt;

  UpdateUserUsecaseParams({
    this.userId,
    required this.email,
    required this.password,
    this.role,
    this.createdAt,
  });
  @override
  List<Object?> get props => [userId];
}

class UpdateUserUsecase
    implements UseCaseWithParams<void, UpdateUserUsecaseParams> {
  final IUserRepository _userRepository;
  UpdateUserUsecase(this._userRepository);
  @override
  Future<Either<Failure, void>> call(UpdateUserUsecaseParams params) {
    final user = UserEntity(email: params.email, password: params.password);
    return _userRepository.updateUser(user);
  }
}

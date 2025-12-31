import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/user_repository.dart';

class CreateUserUsecaseParams extends Equatable {
  final String email;
  final String password;

  const CreateUserUsecaseParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class CreateUserUsecase
    implements UseCaseWithParams<void, CreateUserUsecaseParams> {
  final IUserRepository _userRepository;
  CreateUserUsecase(this._userRepository);

  @override
  Future<Either<Failure, void>> call(CreateUserUsecaseParams params) {
    final user = UserEntity(email: params.email, password: params.password);
    return _userRepository.createUser(user);
  }
}

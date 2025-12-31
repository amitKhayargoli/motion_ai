import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/auth/domain/repositories/user_repository.dart';

class GetUserByIdParams extends Equatable {
  final String userId;

  GetUserByIdParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetUserById implements UseCaseWithParams<void, GetUserByIdParams> {
  final IUserRepository _userRepository;

  GetUserById(this._userRepository);

  @override
  Future<Either<Failure, void>> call(GetUserByIdParams params) {
    return _userRepository.getUserById(params.userId);
  }
}

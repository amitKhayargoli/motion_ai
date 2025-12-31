import 'package:dartz/dartz.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/auth/domain/repositories/user_repository.dart';

class GetAllUsersUsecase implements UseCaseWithoutParams {
  final IUserRepository _userRepository;
  GetAllUsersUsecase(this._userRepository);
  @override
  Future<Either<Failure, dynamic>> call() {
    return _userRepository.getAllUsers();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/auth/domain/entities/user_entity.dart';
import 'package:motion_ai/feature/auth/domain/usecases/create_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/delete_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/get_all_users_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/get_user_by_id_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/update_user_usecase.dart';
import 'package:motion_ai/feature/auth/presentation/state/user_state.dart';

class UserViewmodel extends Notifier<UserState> {
  late final GetAllUsersUsecase _getAllUserUsecase;
  late final CreateUserUsecase _craeteUserUsecase;
  late final DeleteUserUsecase _deleteUserUsecase;
  late final UpdateUserUsecase _updateUserUsecase;
  late final GetUserByIdUsecase _getUserByIdUsecase;

  @override
  UserState build() {
    return const UserState();
  }

  Future<void> getAllUsers() async {
    state = state.copyWith(status: UserStatus.loading);

    final result = await _getAllUserUsecase();

    result.fold(
      (failure) => state = state.copyWith(
        status: UserStatus.error,
        errorMessage: failure.message,
      ),
      (users) =>
          state = state.copyWith(status: UserStatus.loaded, users: users),
    );
  }

  Future<void> getUserById(String userId) async {
    state = state.copyWith(status: UserStatus.loading);

    final result = await _getUserByIdUsecase(
      GetUserByIdUsecaseParams(userId: userId),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: UserStatus.error,
        errorMessage: failure.message,
      ),
      (users) =>
          state = state.copyWith(status: UserStatus.loaded, users: users),
    );
  }

  Future<void> createUser(String email, String password) async {
    state = state.copyWith(status: UserStatus.loading);

    final result = await _craeteUserUsecase(
      CreateUserUsecaseParams(email: email, password: password),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: UserStatus.error,
        errorMessage: failure.message,
      ),
      (_) => {state = state.copyWith(status: UserStatus.created)},
    );
  }

  Future<void> updateUser({
    String? userId,
    required String email,
    required String password,
    userRole? role,
    DateTime? createdAt,
  }) async {
    state = state.copyWith(status: UserStatus.loading);

    final result = await _updateUserUsecase(
      UpdateUserUsecaseParams(
        userId: userId,
        email: email,
        password: password,
        role: role,
        createdAt: createdAt,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: UserStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(status: UserStatus.updated);
        getAllUsers();
      },
    );
  }

  Future<void> deleteUser(String userId) async {
    state = state.copyWith(status: UserStatus.loading);

    final result = await _deleteUserUsecase(
      DeleteUserUsecaseParams(userId: userId),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: UserStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        state = state.copyWith(status: UserStatus.deleted);
        getAllUsers();
      },
    );
  }
}

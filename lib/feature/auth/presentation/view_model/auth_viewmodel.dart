import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/login_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/register_usecase.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';
import 'package:motion_ai/feature/auth/domain/usecases/update_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/upload_image_usecase.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

class AuthViewModel extends Notifier<AuthState> {
  late final RegisterUsecase _registerUsecase;
  late final LoginUsecase _loginUsecase;
  late final GetCurrentUserUsecase _getCurrentUserUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final UploadImageUsecase _uploadImageUsecase;
  late final UpdateUserUsecase _updateUserUsecase;

  @override
  AuthState build() {
    _registerUsecase = ref.read(registerUsecaseProvider);
    _loginUsecase = ref.read(loginUsecaseProvider);
    _getCurrentUserUsecase = ref.read(getCurrentUserUsecaseProvider);
    _logoutUsecase = ref.read(logoutUsecaseProvider);
    _uploadImageUsecase = ref.read(uploadImageUsecaseProvider);
    _updateUserUsecase = ref.read(updateUserUsecaseProvider);
    return const AuthState();
  }

  Future<void> register({
    String? username,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final result = await _registerUsecase(
        RegisterParams(username: username, email: email, password: password),
      );

      result.fold(
        (failure) => state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        ),
        (_) => state = state.copyWith(status: AuthStatus.registered),
      );
    } catch (e, st) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _loginUsecase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) =>
          state = state.copyWith(status: AuthStatus.authenticated, user: user),
    );
  }

  Future<void> getCurrentUser() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _getCurrentUserUsecase();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ),
      (user) =>
          state = state.copyWith(status: AuthStatus.authenticated, user: user),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _logoutUsecase();

    if (result.isLeft()) {
      result.fold(
        (failure) => state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        ),
        (_) {},
      );
      return;
    }

    // Clear audio Hive cache so the next user starts fresh
    await ref.read(audioViewModelProvider.notifier).clearAudios();

    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  //upload photo
  Future<void> uploadImage(File image) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _uploadImageUsecase(image);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (imageName) {
        state = state.copyWith(
          status: AuthStatus.loaded,
          uploadPhotoName: imageName,
        );
      },
    );
  }

  Future<void> updateUser({String? username, String? password}) async {
    final email = state.user?.email;
    if (email == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No authenticated user found',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _updateUserUsecase(
      UpdateUserUsecaseParams(
        email: email,
        username: username,
        password: password,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (_) {
        final updatedUser = state.user != null
            ? AuthEntity(
                userId: state.user!.userId,
                email: state.user!.email,
                password: password ?? state.user!.password,
                username: username ?? state.user!.username,
                createdAt: state.user!.createdAt,
                profilePicture: state.user!.profilePicture,
              )
            : state.user;
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
        );
      },
    );
  }
}

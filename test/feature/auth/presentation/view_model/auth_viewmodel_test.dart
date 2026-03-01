import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/delete_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/get_audios_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/update_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/domain/usecases/upload_audio_usecase.dart';
import 'package:motion_ai/feature/audio_file/presentation/view_model/audio_view_model.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';
import 'package:motion_ai/feature/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/login_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/register_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/update_user_usecase.dart';
import 'package:motion_ai/feature/auth/domain/usecases/upload_image_usecase.dart';
import 'package:motion_ai/feature/auth/presentation/state/auth_state.dart';
import 'package:motion_ai/feature/auth/presentation/view_model/auth_viewmodel.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/providers/providers.dart';

// --- Mocks ---
class MockRegisterUsecase extends Mock implements RegisterUsecase {}

class MockLoginUsecase extends Mock implements LoginUsecase {}

class MockGetCurrentUserUsecase extends Mock implements GetCurrentUserUsecase {}

class MockLogoutUsecase extends Mock implements LogoutUsecase {}

class MockUploadImageUsecase extends Mock implements UploadImageUsecase {}

class MockUpdateUserUsecase extends Mock implements UpdateUserUsecase {}

class MockUploadAudioUsecase extends Mock implements UploadAudioUsecase {}

class MockGetAudiosUsecase extends Mock implements GetAudiosUsecase {}

class MockUpdateAudioUsecase extends Mock implements UpdateAudioUsecase {}

class MockDeleteAudioUsecase extends Mock implements DeleteAudioUsecase {}

class MockAudioLocalDatasource extends Mock implements IAudioLocalDatasource {}

class MockUserSessionService extends Mock implements UserSessionService {}

class MockFile extends Mock implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(const RegisterParams(email: '', password: ''));
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const GetAudiosParams(userId: ''));
    registerFallbackValue(File(''));
  });

  late MockRegisterUsecase mockRegisterUsecase;
  late MockLoginUsecase mockLoginUsecase;
  late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
  late MockLogoutUsecase mockLogoutUsecase;
  late MockUploadImageUsecase mockUploadImageUsecase;
  late MockUpdateUserUsecase mockUpdateUserUsecase;
  late MockUploadAudioUsecase mockUploadAudioUsecase;
  late MockGetAudiosUsecase mockGetAudiosUsecase;
  late MockUpdateAudioUsecase mockUpdateAudioUsecase;
  late MockDeleteAudioUsecase mockDeleteAudioUsecase;
  late MockAudioLocalDatasource mockAudioLocalDatasource;
  late MockUserSessionService mockUserSessionService;
  late ProviderContainer container;

  const tEmail = 'test@gmail.com';
  const tPassword = 'password123';
  const tUser = AuthEntity(
    userId: '1',
    email: tEmail,
    password: tPassword,
    username: 'testuser',
  );

  setUp(() {
    mockRegisterUsecase = MockRegisterUsecase();
    mockLoginUsecase = MockLoginUsecase();
    mockGetCurrentUserUsecase = MockGetCurrentUserUsecase();
    mockLogoutUsecase = MockLogoutUsecase();
    mockUploadImageUsecase = MockUploadImageUsecase();
    mockUpdateUserUsecase = MockUpdateUserUsecase();
    mockUploadAudioUsecase = MockUploadAudioUsecase();
    mockGetAudiosUsecase = MockGetAudiosUsecase();
    mockUpdateAudioUsecase = MockUpdateAudioUsecase();
    mockDeleteAudioUsecase = MockDeleteAudioUsecase();
    mockAudioLocalDatasource = MockAudioLocalDatasource();
    mockUserSessionService = MockUserSessionService();

    // Stub AudioViewModel's loadInitialData dependencies so the
    // microtask triggered in AudioViewModel.build() doesn't crash.
    when(() => mockAudioLocalDatasource.getStoredAudios())
        .thenAnswer((_) async => []);
    when(() => mockUserSessionService.getUserId()).thenReturn('test_user');
    when(() => mockGetAudiosUsecase(any()))
        .thenAnswer((_) async => const Right([]));

    container = ProviderContainer(
      overrides: [
        registerUsecaseProvider.overrideWithValue(mockRegisterUsecase),
        loginUsecaseProvider.overrideWithValue(mockLoginUsecase),
        getCurrentUserUsecaseProvider
            .overrideWithValue(mockGetCurrentUserUsecase),
        logoutUsecaseProvider.overrideWithValue(mockLogoutUsecase),
        uploadImageUsecaseProvider.overrideWithValue(mockUploadImageUsecase),
        updateUserUsecaseProvider.overrideWithValue(mockUpdateUserUsecase),
        uploadAudioUsecaseProvider.overrideWithValue(mockUploadAudioUsecase),
        getAudiosUsecaseProvider.overrideWithValue(mockGetAudiosUsecase),
        updateAudioUsecaseProvider.overrideWithValue(mockUpdateAudioUsecase),
        deleteAudioUsecaseProvider.overrideWithValue(mockDeleteAudioUsecase),
        audioLocalDatasourceProvider
            .overrideWithValue(mockAudioLocalDatasource),
        userSessionServiceProvider.overrideWithValue(mockUserSessionService),
      ],
    );
  });

  tearDown(() async {
    // Let pending microtasks (from AudioViewModel.build) drain before disposal.
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    container.dispose();
  });

  AuthState readState() => container.read(authViewModelProvider);

  AuthViewModel readNotifier() =>
      container.read(authViewModelProvider.notifier);

  // ─── register ────────────────────────────────────────────────────────

  group('register', () {
    test('should set state to registered on success', () async {
      // arrange
      when(
        () => mockRegisterUsecase(any()),
      ).thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().register(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.registered);
      expect(state.errorMessage, isNull);
      verify(
        () => mockRegisterUsecase(
          const RegisterParams(email: tEmail, password: tPassword),
        ),
      ).called(1);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Email already exists');
      when(
        () => mockRegisterUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().register(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Email already exists');
    });

    test('should set state to error on NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockRegisterUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().register(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Network connection failed');
    });

    test('should set state to error when usecase throws an exception',
        () async {
      // arrange
      when(
        () => mockRegisterUsecase(any()),
      ).thenThrow(Exception('Unexpected'));

      // act
      await readNotifier().register(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, isNotNull);
    });

    test('should clear errorMessage when transitioning to loading', () async {
      // arrange — first put viewmodel into error state
      const failure = ApiFailure(message: 'fail');
      when(
        () => mockRegisterUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));
      await readNotifier().register(email: tEmail, password: tPassword);
      expect(readState().errorMessage, 'fail');

      // arrange — next call succeeds
      when(
        () => mockRegisterUsecase(any()),
      ).thenAnswer((_) async => const Right(true));

      // act
      await readNotifier().register(email: tEmail, password: tPassword);

      // assert
      expect(readState().errorMessage, isNull);
      expect(readState().status, AuthStatus.registered);
    });
  });

  // ─── login ───────────────────────────────────────────────────────────

  group('login', () {
    test('should set state to authenticated with user on success', () async {
      // arrange
      when(
        () => mockLoginUsecase(any()),
      ).thenAnswer((_) async => const Right(tUser));

      // act
      await readNotifier().login(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, tUser);
      verify(
        () => mockLoginUsecase(
          const LoginParams(email: tEmail, password: tPassword),
        ),
      ).called(1);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Invalid credentials');
      when(
        () => mockLoginUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().login(email: tEmail, password: tPassword);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Invalid credentials');
    });

    test('should set state to error on NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockLoginUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().login(email: tEmail, password: tPassword);

      // assert
      expect(readState().status, AuthStatus.error);
      expect(readState().errorMessage, 'Network connection failed');
    });

    test('should pass correct params to loginUsecase', () async {
      // arrange
      when(
        () => mockLoginUsecase(any()),
      ).thenAnswer((_) async => const Right(tUser));

      // act
      await readNotifier().login(email: tEmail, password: tPassword);

      // assert
      verify(
        () => mockLoginUsecase(
          const LoginParams(email: tEmail, password: tPassword),
        ),
      ).called(1);
    });
  });

  // ─── getCurrentUser ──────────────────────────────────────────────────

  group('getCurrentUser', () {
    test('should set state to authenticated with user on success', () async {
      // arrange
      when(
        () => mockGetCurrentUserUsecase(),
      ).thenAnswer((_) async => const Right(tUser));

      // act
      await readNotifier().getCurrentUser();

      // assert
      final state = readState();
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, tUser);
      verify(() => mockGetCurrentUserUsecase()).called(1);
    });

    test('should set state to unauthenticated on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'No session found');
      when(
        () => mockGetCurrentUserUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().getCurrentUser();

      // assert
      final state = readState();
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'No session found');
    });

    test('should set unauthenticated on LocalDatabaseFailure', () async {
      // arrange
      const failure = LocalDatabaseFailure(message: 'Hive error');
      when(
        () => mockGetCurrentUserUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().getCurrentUser();

      // assert
      expect(readState().status, AuthStatus.unauthenticated);
      expect(readState().errorMessage, 'Hive error');
    });
  });

  // ─── logout ──────────────────────────────────────────────────────────

  group('logout', () {
    test('should set state to unauthenticated and clear user on success',
        () async {
      // arrange
      when(() => mockLogoutUsecase())
          .thenAnswer((_) async => const Right(true));
      when(() => mockAudioLocalDatasource.clearAll())
          .thenAnswer((_) async => {});

      // act
      await readNotifier().logout();

      // assert
      final state = readState();
      expect(state.status, AuthStatus.unauthenticated);
      verify(() => mockLogoutUsecase()).called(1);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Logout failed');
      when(
        () => mockLogoutUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().logout();

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Logout failed');
    });

    test('should clear audio cache on successful logout', () async {
      // arrange
      when(() => mockLogoutUsecase())
          .thenAnswer((_) async => const Right(true));
      when(() => mockAudioLocalDatasource.clearAll())
          .thenAnswer((_) async => {});

      // act
      await readNotifier().logout();

      // assert
      verify(() => mockAudioLocalDatasource.clearAll()).called(1);
    });

    test('should NOT clear audio cache when logout fails', () async {
      // arrange
      const failure = ApiFailure(message: 'Logout failed');
      when(
        () => mockLogoutUsecase(),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().logout();

      // assert
      verifyNever(() => mockAudioLocalDatasource.clearAll());
    });
  });

  // ─── uploadImage ─────────────────────────────────────────────────────

  group('uploadImage', () {
    late MockFile mockFile;

    setUp(() {
      mockFile = MockFile();
    });

    test('should set state to loaded with uploadPhotoName on success',
        () async {
      // arrange
      when(
        () => mockUploadImageUsecase(mockFile),
      ).thenAnswer((_) async => const Right('profile_photo.jpg'));

      // act
      await readNotifier().uploadImage(mockFile);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.loaded);
      expect(state.uploadPhotoName, 'profile_photo.jpg');
      verify(() => mockUploadImageUsecase(mockFile)).called(1);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Upload failed');
      when(
        () => mockUploadImageUsecase(mockFile),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().uploadImage(mockFile);

      // assert
      final state = readState();
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Upload failed');
    });

    test('should set state to error on NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(
        () => mockUploadImageUsecase(mockFile),
      ).thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().uploadImage(mockFile);

      // assert
      expect(readState().status, AuthStatus.error);
      expect(readState().errorMessage, 'Network connection failed');
    });
  });

  // ─── clearError ──────────────────────────────────────────────────────

  group('clearError', () {
    test('should clear errorMessage from state', () async {
      // arrange — put into error state first
      const failure = ApiFailure(message: 'some error');
      when(
        () => mockLoginUsecase(any()),
      ).thenAnswer((_) async => const Left(failure));
      await readNotifier().login(email: tEmail, password: tPassword);
      expect(readState().errorMessage, 'some error');

      // act
      readNotifier().clearError();

      // assert
      expect(readState().errorMessage, isNull);
    });
  });

  // ─── initial state ──────────────────────────────────────────────────

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.uploadPhotoName, isNull);
    });
  });
}

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/auth/domain/entities/auth_entity.dart';
import 'package:motion_ai/feature/auth/domain/repositories/auth_repository.dart';
import 'package:motion_ai/feature/auth/domain/usecases/update_user_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late UpdateUserUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = UpdateUserUsecase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(
      const AuthEntity(email: 'test@example.com', password: 'password123'),
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';

  group('UpdateUserUsecase', () {
    test('should pass AuthEntity with correct values to repository', () async {
      // Arrange
      AuthEntity? capturedEntity;

      when(() => mockRepository.updateUser(any())).thenAnswer((
        invocation,
      ) async {
        capturedEntity = invocation.positionalArguments.first as AuthEntity;
        return const Right(true);
      });

      // Act
      await usecase(
        const UpdateUserUsecaseParams(email: tEmail, password: tPassword),
      );

      // Assert
      expect(capturedEntity?.email, tEmail);
      expect(capturedEntity?.password, tPassword);
    });

    test('should return ApiFailure when update fails', () async {
      // Arrange
      const failure = ApiFailure(message: 'Update failed');

      when(
        () => mockRepository.updateUser(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(
        const UpdateUserUsecaseParams(email: tEmail, password: tPassword),
      );

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.updateUser(any())).called(1);
    });

    test('should return NetworkFailure when there is no internet', () async {
      // Arrange
      const failure = NetworkFailure();

      when(
        () => mockRepository.updateUser(any()),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(
        const UpdateUserUsecaseParams(email: tEmail, password: tPassword),
      );

      // Assert
      expect(result, const Left(failure));
    });
  });

  group('UpdateUserUsecaseParams', () {
    test('should support value equality', () {
      // Arrange
      const params1 = UpdateUserUsecaseParams(
        email: tEmail,
        password: tPassword,
      );

      const params2 = UpdateUserUsecaseParams(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(params1, params2);
    });

    test('props should contain correct values', () {
      // Arrange
      const params = UpdateUserUsecaseParams(
        email: tEmail,
        password: tPassword,
      );

      // Assert
      expect(params.props, [null, tEmail, tPassword, null, null]);
    });
  });
}

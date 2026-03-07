import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/entities/chat_thread_entity.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/create_thread_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late CreateThreadUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = CreateThreadUseCase(mockRepository);
  });

  const tWorkspaceId = 'ws-123';
  const tTitle = 'New chat';

  final tThread = ChatThreadEntity(
    id: 'thread-1',
    workspaceId: tWorkspaceId,
    userId: 'user-1',
    title: tTitle,
    createdAt: DateTime(2025, 1, 1),
    messages: const [],
  );

  group('CreateThreadUseCase', () {
    test('should return thread on success', () async {
      // arrange
      when(() => mockRepository.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      final result = await usecase(
        CreateThreadParams(workspaceId: tWorkspaceId, title: tTitle),
      );

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createThread(
            workspaceId: tWorkspaceId,
            title: tTitle,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass null title when not provided', () async {
      // arrange
      when(() => mockRepository.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => Right(tThread));

      // act
      await usecase(CreateThreadParams(workspaceId: tWorkspaceId));

      // assert
      verify(() => mockRepository.createThread(
            workspaceId: tWorkspaceId,
            title: null,
          )).called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Create failed', statusCode: 500);
      when(() => mockRepository.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        CreateThreadParams(workspaceId: tWorkspaceId, title: tTitle),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.createThread(
            workspaceId: any(named: 'workspaceId'),
            title: any(named: 'title'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(
        CreateThreadParams(workspaceId: tWorkspaceId),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}

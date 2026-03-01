import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/repositories/rag_chatbot_repository.dart';
import 'package:motion_ai/feature/rag_chatbot/domain/usecases/delete_thread_usecase.dart';

class MockRagChatbotRepository extends Mock implements IRagChatbotRepository {}

void main() {
  late DeleteThreadUseCase usecase;
  late MockRagChatbotRepository mockRepository;

  setUp(() {
    mockRepository = MockRagChatbotRepository();
    usecase = DeleteThreadUseCase(mockRepository);
  });

  const tThreadId = 'thread-123';

  group('DeleteThreadUseCase', () {
    test('should return true on success', () async {
      // arrange
      when(() => mockRepository.deleteThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      final result = await usecase(DeleteThreadParams(threadId: tThreadId));

      // assert
      expect(result, const Right(true));
      verify(() => mockRepository.deleteThread(threadId: tThreadId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct thread id to repository', () async {
      // arrange
      when(() => mockRepository.deleteThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Right(true));

      // act
      await usecase(DeleteThreadParams(threadId: 'thread-other'));

      // assert
      verify(() => mockRepository.deleteThread(threadId: 'thread-other'))
          .called(1);
    });

    test('should return ApiFailure on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Delete failed', statusCode: 403);
      when(() => mockRepository.deleteThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(DeleteThreadParams(threadId: tThreadId));

      // assert
      expect(result, const Left(failure));
    });

    test('should return NetworkFailure on network error', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockRepository.deleteThread(
            threadId: any(named: 'threadId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await usecase(DeleteThreadParams(threadId: tThreadId));

      // assert
      expect(result, const Left(failure));
    });
  });
}

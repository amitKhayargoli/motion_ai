import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/feature/notes/domain/entities/note_entity.dart';
import 'package:motion_ai/feature/notes/domain/usecases/get_transcript_usecase.dart';
import 'package:motion_ai/feature/notes/domain/usecases/transcribe_audio_usecase.dart';
import 'package:motion_ai/feature/notes/presentation/state/transcript_state.dart';
import 'package:motion_ai/feature/notes/presentation/view_model/transcript_view_model.dart';

// --- Mocks ---
class MockGetTranscriptUseCase extends Mock
    implements GetTranscriptByAudioFileIdUseCase {}

class MockTranscribeAudioUseCase extends Mock
    implements TranscribeAudioUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetTranscriptParams(''));
    registerFallbackValue(
      const TranscribeAudioParams(audioFileId: '', workspaceId: ''),
    );
  });

  late MockGetTranscriptUseCase mockGetTranscript;
  late MockTranscribeAudioUseCase mockTranscribeAudio;
  late ProviderContainer container;

  const tAudioFileId = 'audio-123';
  const tWorkspaceId = 'ws-123';

  final tNote = NoteEntity(
    id: 'note-1',
    workspaceId: tWorkspaceId,
    title: 'Transcript',
    content: 'Transcribed text',
    audioFileId: tAudioFileId,
    type: 'VOICE_TRANSCRIPT',
    createdAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockGetTranscript = MockGetTranscriptUseCase();
    mockTranscribeAudio = MockTranscribeAudioUseCase();

    container = ProviderContainer(
      overrides: [
        getTranscriptUseCaseProvider.overrideWithValue(mockGetTranscript),
        transcribeAudioUseCaseProvider.overrideWithValue(mockTranscribeAudio),
      ],
    );

    // Keep a listener alive so the auto-dispose provider doesn't dispose
    // between reads.
    container.listen(transcriptViewModelProvider, (_, __) {});
  });

  tearDown(() {
    container.dispose();
  });

  TranscriptState readState() => container.read(transcriptViewModelProvider);

  TranscriptViewModel readNotifier() =>
      container.read(transcriptViewModelProvider.notifier);

  // ─── initial state ──────────────────────────────────────────────────

  group('initial state', () {
    test('should have correct initial values', () {
      final state = readState();
      expect(state.status, TranscriptStatus.initial);
      expect(state.note, isNull);
      expect(state.error, isNull);
    });
  });

  // ─── fetchTranscript ────────────────────────────────────────────────

  group('fetchTranscript', () {
    test('should set state to loaded with note on success', () async {
      // arrange
      when(() => mockGetTranscript(any()))
          .thenAnswer((_) async => Right(tNote));

      // act
      await readNotifier().fetchTranscript(tAudioFileId);

      // assert
      final state = readState();
      expect(state.status, TranscriptStatus.loaded);
      expect(state.note, tNote);
      expect(state.error, isNull);
      verify(() => mockGetTranscript(any())).called(1);
    });

    test('should set state to loaded with null note when not found', () async {
      // arrange
      when(() => mockGetTranscript(any()))
          .thenAnswer((_) async => const Right(null));

      // act
      await readNotifier().fetchTranscript(tAudioFileId);

      // assert
      final state = readState();
      expect(state.status, TranscriptStatus.loaded);
      expect(state.note, isNull);
    });

    test('should set state to error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Not found', statusCode: 404);
      when(() => mockGetTranscript(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().fetchTranscript(tAudioFileId);

      // assert
      final state = readState();
      expect(state.status, TranscriptStatus.error);
      expect(state.error, 'Not found');
    });

    test('should set state to error on NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockGetTranscript(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      await readNotifier().fetchTranscript(tAudioFileId);

      // assert
      expect(readState().status, TranscriptStatus.error);
      expect(readState().error, 'Network connection failed');
    });

    test('should reset state before fetching', () async {
      // arrange — start with a loaded note
      when(() => mockGetTranscript(any()))
          .thenAnswer((_) async => Right(tNote));
      await readNotifier().fetchTranscript(tAudioFileId);
      expect(readState().note, tNote);

      // arrange — capture status during second call
      TranscriptStatus? capturedStatus;
      when(() => mockGetTranscript(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return const Right(null);
      });

      // act
      await readNotifier().fetchTranscript('audio-other');

      // assert
      expect(capturedStatus, TranscriptStatus.loading);
    });
  });

  // ─── transcribeAudio ────────────────────────────────────────────────

  group('transcribeAudio', () {
    test('should set state to loaded with note and return true on success',
        () async {
      // arrange
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => Right(tNote));

      // act
      final result = await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
        noteTitle: 'My Recording',
      );

      // assert
      expect(result, true);
      final state = readState();
      expect(state.status, TranscriptStatus.loaded);
      expect(state.note, tNote);
    });

    test('should return false and set error on failure', () async {
      // arrange
      const failure = ApiFailure(message: 'Transcription failed');
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
      );

      // assert
      expect(result, false);
      expect(readState().status, TranscriptStatus.error);
      expect(readState().error, 'Transcription failed');
    });

    test('should return false on NetworkFailure', () async {
      // arrange
      const failure = NetworkFailure();
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
      );

      // assert
      expect(result, false);
      expect(readState().status, TranscriptStatus.error);
    });

    test('should set status to loading before the call', () async {
      // arrange
      TranscriptStatus? capturedStatus;
      when(() => mockTranscribeAudio(any())).thenAnswer((_) async {
        capturedStatus = readState().status;
        return Right(tNote);
      });

      // act
      await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
      );

      // assert
      expect(capturedStatus, TranscriptStatus.loading);
    });

    test('should pass correct params including optional noteTitle', () async {
      // arrange
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => Right(tNote));

      // act
      await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
        noteTitle: 'Custom Title',
      );

      // assert
      final captured =
          verify(() => mockTranscribeAudio(captureAny())).captured;
      expect(captured.length, 1);
      final params = captured.first as TranscribeAudioParams;
      expect(params.audioFileId, tAudioFileId);
      expect(params.workspaceId, tWorkspaceId);
      expect(params.noteTitle, 'Custom Title');
    });

    test('should clear previous error on new call', () async {
      // arrange — first fail
      const failure = ApiFailure(message: 'first error');
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => const Left(failure));
      await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
      );
      expect(readState().error, 'first error');

      // arrange — then succeed
      when(() => mockTranscribeAudio(any()))
          .thenAnswer((_) async => Right(tNote));

      // act
      await readNotifier().transcribeAudio(
        audioFileId: tAudioFileId,
        workspaceId: tWorkspaceId,
      );

      // assert
      expect(readState().error, isNull);
      expect(readState().status, TranscriptStatus.loaded);
    });
  });
}

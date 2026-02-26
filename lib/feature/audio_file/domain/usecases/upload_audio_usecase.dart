import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:motion_ai/feature/audio_file/data/repositories/audio_file_repository.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/repositories/audio_file_repository.dart';

class UploadAudioParams extends Equatable {
  final String filePath;
  final int durationSeconds;
  final String? title;
  final String? fileName;

  const UploadAudioParams({
    required this.filePath,
    required this.durationSeconds,
    this.title,
    this.fileName,
  });

  @override
  List<Object?> get props => [filePath, durationSeconds, title, fileName];
}

// Create Provider
final uploadAudioUsecaseProvider = Provider<UploadAudioUsecase>((ref) {
  final audioRepository = ref.read(audioFileRepositoryProvider);
  final userSessionService = ref.read(userSessionServiceProvider);
  return UploadAudioUsecase(
    audioRepository: audioRepository,
    userSessionService: userSessionService,
  );
});

class UploadAudioUsecase
    implements UseCaseWithParams<AudioFileEntity, UploadAudioParams> {
  final IAudioFileRepository _audioRepository;

  final UserSessionService _userSessionService;

  UploadAudioUsecase({
    required IAudioFileRepository audioRepository,
    required UserSessionService userSessionService,
  })  : _audioRepository = audioRepository,
        _userSessionService = userSessionService;

  @override
  Future<Either<Failure, AudioFileEntity>> call(UploadAudioParams params) {
    final audioEntity = AudioFileEntity(
      localPath: params.filePath,
      durationSeconds: params.durationSeconds,
      title: params.title,
      fileName: params.fileName,
      uploaderId: _userSessionService.getUserId()!,
      username: _userSessionService.getUsername()!,
    );

    return _audioRepository.uploadAudio(audioEntity);
  }
}

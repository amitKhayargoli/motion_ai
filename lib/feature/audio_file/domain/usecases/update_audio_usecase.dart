import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/audio_file/data/repositories/audio_file_repository.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/repositories/audio_file_repository.dart';

class UpdateAudioParams extends Equatable {
  final String audioId;
  final String? title;

  const UpdateAudioParams({required this.audioId, this.title});

  @override
  List<Object?> get props => [audioId, title];
}

final updateAudioUsecaseProvider = Provider<UpdateAudioUsecase>((ref) {
  final audioRepository = ref.read(audioFileRepositoryProvider);
  return UpdateAudioUsecase(audioRepository: audioRepository);
});

class UpdateAudioUsecase
    implements UseCaseWithParams<AudioFileEntity, UpdateAudioParams> {
  final IAudioFileRepository _audioRepository;

  UpdateAudioUsecase({required IAudioFileRepository audioRepository})
      : _audioRepository = audioRepository;

  @override
  Future<Either<Failure, AudioFileEntity>> call(UpdateAudioParams params) {
    return _audioRepository.updateAudio(params.audioId, title: params.title);
  }
}

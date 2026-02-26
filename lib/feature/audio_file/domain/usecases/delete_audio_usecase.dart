import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/audio_file/data/repositories/audio_file_repository.dart';
import 'package:motion_ai/feature/audio_file/domain/repositories/audio_file_repository.dart';

class DeleteAudioParams extends Equatable {
  final String audioId;

  const DeleteAudioParams({required this.audioId});

  @override
  List<Object?> get props => [audioId];
}

final deleteAudioUsecaseProvider = Provider<DeleteAudioUsecase>((ref) {
  final audioRepository = ref.read(audioFileRepositoryProvider);
  return DeleteAudioUsecase(audioRepository: audioRepository);
});

class DeleteAudioUsecase implements UseCaseWithParams<bool, DeleteAudioParams> {
  final IAudioFileRepository _audioRepository;

  DeleteAudioUsecase({required IAudioFileRepository audioRepository})
      : _audioRepository = audioRepository;

  @override
  Future<Either<Failure, bool>> call(DeleteAudioParams params) {
    return _audioRepository.deleteAudio(params.audioId);
  }
}

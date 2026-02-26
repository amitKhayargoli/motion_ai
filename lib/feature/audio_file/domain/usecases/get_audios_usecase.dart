import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/error/failures.dart';
import 'package:motion_ai/core/usecases/app_usecase.dart';
import 'package:motion_ai/feature/audio_file/data/repositories/audio_file_repository.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';
import 'package:motion_ai/feature/audio_file/domain/repositories/audio_file_repository.dart';

class GetAudiosParams extends Equatable {
  final String userId;

  const GetAudiosParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Create Provider
final getAudiosUsecaseProvider = Provider<GetAudiosUsecase>((ref) {
  final audioRepository = ref.read(audioFileRepositoryProvider);
  return GetAudiosUsecase(audioRepository: audioRepository);
});

class GetAudiosUsecase
    implements UseCaseWithParams<List<AudioFileEntity>, GetAudiosParams> {
  final IAudioFileRepository _audioRepository;

  GetAudiosUsecase({required IAudioFileRepository audioRepository})
    : _audioRepository = audioRepository;

  @override
  Future<Either<Failure, List<AudioFileEntity>>> call(GetAudiosParams params) {
    return _audioRepository.getUserAudioFiles(params.userId);
  }
}

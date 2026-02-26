// filepath: c:\Users\amit\Downloads\motion_ai\lib\feature\audio_file\presentation\state\audio_state.dart
import 'package:equatable/equatable.dart';
import 'package:motion_ai/feature/audio_file/domain/entities/audio_file_entity.dart';

enum AudioStatus { initial, loading, success, error }

class AudioState extends Equatable {
  const AudioState({
    this.status = AudioStatus.initial,
    this.audios, // Changed from audioFiles to audios
    this.errorMessage,
  });

  final AudioStatus status;
  final List<AudioFileEntity>? audios; // Nullable list
  final String? errorMessage;

  AudioState copyWith({
    AudioStatus? status,
    List<AudioFileEntity>? audios, // Updated parameter
    String? errorMessage,
  }) {
    return AudioState(
      status: status ?? this.status,
      audios: audios ?? this.audios, // Updated
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, audios, errorMessage];
}

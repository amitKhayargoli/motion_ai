import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_ai/core/api/api_client.dart';
import 'package:motion_ai/core/api/api_endpoints.dart';
import 'package:motion_ai/core/providers/providers.dart';
import 'package:motion_ai/core/services/storage/token_service.dart';
import 'package:motion_ai/core/services/storage/user_session_service.dart';
import 'package:motion_ai/feature/audio_file/data/datasources/audio_file_datasource.dart';
import 'package:motion_ai/feature/audio_file/data/models/audio_file_api_model.dart';
import 'package:http_parser/http_parser.dart';

final audioFileRemoteDatasourceProvider = Provider<IAudioRemoteDatasource>((
  ref,
) {
  return AudioFileRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    tokenService: ref.read(tokenServiceProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AudioFileRemoteDatasource implements IAudioRemoteDatasource {
  final ApiClient _apiClient;
  final TokenService _tokenService;
  final UserSessionService _userSessionService;

  AudioFileRemoteDatasource({
    required ApiClient apiClient,
    required TokenService tokenService,
    required UserSessionService userSessionService,
  }) : _apiClient = apiClient,
       _tokenService = tokenService,
       _userSessionService = userSessionService;

  @override
  Future<AudioFileApiModel> uploadAudio({
    required String filePath,
    required int durationSeconds,
  }) async {
    try {
      print('🔵 Starting audio upload...');

      final uploaderId = _userSessionService.getUserId();
      print('🔵 Uploader ID: $uploaderId');

      if (uploaderId == null || uploaderId.isEmpty) {
        throw StateError('Uploader ID not found. User not logged in.');
      }

      // ✅ Validate duration
      if (durationSeconds <= 0) {
        throw Exception(
          'Duration must be greater than 0. Got: $durationSeconds',
        );
      }

      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File not found at: $filePath');
      }

      final fileSize = await file.length();
      print('🔵 File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final fileName = file.path.split('/').last;
      print('🔵 File name: $fileName');
      print('🔵 Duration: $durationSeconds seconds');

      // Set MIME type based on file extension
      MediaType contentType;
      if (fileName.endsWith('.aac')) {
        contentType = MediaType('audio', 'aac');
      } else if (fileName.endsWith('.m4a')) {
        contentType = MediaType('audio', 'mp4');
      } else if (fileName.endsWith('.mp3')) {
        contentType = MediaType('audio', 'mpeg');
      } else if (fileName.endsWith('.wav')) {
        contentType = MediaType('audio', 'wav');
      } else {
        contentType = MediaType('audio', 'aac');
      }

      print('🔵 Content-Type: $contentType');

      // ✅ Include both audio file AND duration
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: contentType,
        ),
        'durationSeconds': durationSeconds, // ✅ Add duration back
      });

      print(
        '🔵 Form fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
      print(
        '🔵 Uploading to: ${ApiEndpoints.baseUrl}${ApiEndpoints.uploadAudio}',
      );
      print('🔵 Sending request...');

      final response = await _apiClient.post(
        ApiEndpoints.uploadAudio,
        data: formData,
      );

      print('✅ Upload successful!');
      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response data: ${response.data}');

      final data = response.data['data'];
      final apiModel = AudioFileApiModel.fromJson(data);

      return AudioFileApiModel(
        id: apiModel.id ?? '',
        fileName: apiModel.fileName,
        cloudUrl: apiModel.cloudUrl,
        durationSeconds: durationSeconds,
        mimeType: apiModel.mimeType,
        uploadedAt: apiModel.uploadedAt,
        uploaderId: uploaderId,
        uploader: apiModel.uploader,
      );
    } on DioException catch (e) {
      print('❌ DIO EXCEPTION');
      print('❌ Status Code: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');

      String errorMessage = 'Upload failed';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ??
              responseData['error'] ??
              'Server error: ${e.response?.statusCode}';
        } else if (responseData is String) {
          if (responseData.contains('Invalid file type')) {
            errorMessage = 'Invalid file type. Only audio files are allowed.';
          } else {
            errorMessage = responseData;
          }
        }
      }

      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<AudioFileApiModel>> getMyAudioFiles() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myAudioFiles);
      final List list = response.data['data'];
      return list.map((e) => AudioFileApiModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error fetching audio files: $e');
      rethrow;
    }
  }

  @override
  Future<List<AudioFileApiModel>> getAudiosByUploader(String uploaderId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.myAudioFiles);
      final List list = response.data['data'];
      return list.map((e) => AudioFileApiModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error fetching audio files for uploader $uploaderId: $e');
      rethrow;
    }
  }
}

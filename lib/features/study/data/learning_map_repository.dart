import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/learning_map.dart';
import '../domain/study_models.dart';

class RemoteLearningMapRepository implements LearningMapRepository {
  RemoteLearningMapRepository(this.dio);
  final Dio dio;
  @override
  Future<LearningMap> load(LearningMapRequest request) async {
    if (!validMapId(request.subtopicId)) {
      throw const FormatException('Subtema inválido.');
    }
    try {
      final response = await dio.get<Object?>(
        '/mapa-aprendizaje/subtemas/${request.subtopicId}',
      );
      return LearningMap.parse(response.data, request);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

class DemoLearningMapRepository implements LearningMapRepository {
  @override
  Future<LearningMap> load(LearningMapRequest request) async {
    final catalog = StudyCatalog.demo(request.area);
    for (final theme in catalog.themes) {
      for (final sub in theme.subtopics) {
        if (sub.id == request.subtopicId) {
          return LearningMap(
            target: LearningMapNode(sub.id, sub.name, theme.id, theme.name),
            previous: const [],
            route: const [],
          );
        }
      }
    }
    throw const ApiError(code: '404', message: 'Subtema demo no disponible.');
  }
}

final learningMapRepositoryProvider = Provider<LearningMapRepository>(
  (ref) => RemoteLearningMapRepository(ref.watch(dioProvider)),
);

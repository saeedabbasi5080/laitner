import 'package:recall/domain/entities/learning_space.dart';

abstract class ISpaceRepository {
  Future<List<LearningSpace>> getAllSpaces();

  Future<LearningSpace?> getSpaceById(String id);

  Future<int> getSpaceCount();

  Future<LearningSpace> addSpace(LearningSpace space);

  Future<LearningSpace> updateSpace(LearningSpace space);

  Future<void> deleteSpace(String id);
}

import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class SpaceLimitReachedException implements Exception {
  const SpaceLimitReachedException();
}

class AddSpaceUseCase {
  AddSpaceUseCase(this._repository);

  final ISpaceRepository _repository;

  Future<LearningSpace> call(LearningSpace space) async {
    final count = await _repository.getSpaceCount();
    if (count >= maxLearningSpaces) {
      throw const SpaceLimitReachedException();
    }
    return _repository.addSpace(space);
  }
}

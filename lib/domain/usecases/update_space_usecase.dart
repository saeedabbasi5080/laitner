import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class UpdateSpaceUseCase {
  UpdateSpaceUseCase(this._repository);

  final ISpaceRepository _repository;

  Future<LearningSpace> call(LearningSpace space) =>
      _repository.updateSpace(space);
}

import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class GetSpacesUseCase {
  GetSpacesUseCase(this._repository);

  final ISpaceRepository _repository;

  Future<List<LearningSpace>> call() => _repository.getAllSpaces();
}

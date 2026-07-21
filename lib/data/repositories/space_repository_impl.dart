import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class SpaceRepositoryImpl implements ISpaceRepository {
  SpaceRepositoryImpl(this._localDataSource);

  final LocalDataSource _localDataSource;

  @override
  Future<List<LearningSpace>> getAllSpaces() => _localDataSource.getAllSpaces();

  @override
  Future<LearningSpace?> getSpaceById(String id) =>
      _localDataSource.getSpaceById(id);

  @override
  Future<int> getSpaceCount() => _localDataSource.getSpaceCount();

  @override
  Future<LearningSpace> addSpace(LearningSpace space) =>
      _localDataSource.addSpace(space);

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) =>
      _localDataSource.updateSpace(space);

  @override
  Future<void> deleteSpace(String id) => _localDataSource.deleteSpace(id);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/space_repository.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';

void main() {
  test('AddSpaceUseCase enforces maxLearningSpaces limit', () async {
    final repository = _FakeSpaceRepository(
      List.generate(
        maxLearningSpaces,
        (index) => LearningSpace(
          id: 'space-$index',
          name: 'Space $index',
          color: DeckColor.lavender,
          createdAt: DateTime(2026, 7, 1),
          sortOrder: index,
        ),
      ),
    );
    final useCase = AddSpaceUseCase(repository);

    expect(
      () => useCase(
        LearningSpace(
          id: 'new',
          name: 'New',
          color: DeckColor.mint,
          createdAt: DateTime(2026, 7, 15),
        ),
      ),
      throwsA(isA<SpaceLimitReachedException>()),
    );
    expect(repository.spaces, hasLength(maxLearningSpaces));
  });
}

class _FakeSpaceRepository implements ISpaceRepository {
  _FakeSpaceRepository(this.spaces);

  final List<LearningSpace> spaces;

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async {
    spaces.add(space);
    return space;
  }

  @override
  Future<void> deleteSpace(String id) async {
    spaces.removeWhere((space) => space.id == id);
  }

  @override
  Future<List<LearningSpace>> getAllSpaces() async => spaces;

  @override
  Future<LearningSpace?> getSpaceById(String id) async =>
      spaces.where((space) => space.id == id).firstOrNull;

  @override
  Future<int> getSpaceCount() async => spaces.length;

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async => space;
}

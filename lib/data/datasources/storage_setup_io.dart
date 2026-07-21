import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recall/data/datasources/isar_local_data_source.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/models/deck_model.dart';
import 'package:recall/data/models/flashcard_model.dart';
import 'package:recall/data/models/space_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalDataSource> createLocalDataSource(
  SharedPreferences prefs,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [SpaceModelSchema, DeckModelSchema, FlashcardModelSchema],
    directory: dir.path,
    name: 'recall',
  );
  return IsarLocalDataSource(isar);
}

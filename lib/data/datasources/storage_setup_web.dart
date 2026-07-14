import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/web_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalDataSource> createLocalDataSource(
  SharedPreferences prefs,
) async {
  return WebLocalDataSource(prefs);
}

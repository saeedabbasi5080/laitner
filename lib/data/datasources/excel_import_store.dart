import 'dart:convert';

import 'package:recall/domain/entities/excel_import.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExcelImportStore {
  ExcelImportStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'recall_excel_imports_v1';

  Future<List<ExcelImport>> getAll() async {
    await _prefs.reload();
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ExcelImport.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ExcelImport?> getById(String id) async {
    final all = await getAll();
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> save(ExcelImport import) async {
    final all = await getAll();
    final index = all.indexWhere((i) => i.id == import.id);
    if (index >= 0) {
      all[index] = import;
    } else {
      all.insert(0, import);
    }
    await _persist(all);
  }

  Future<void> delete(String id) async {
    final all = await getAll()..removeWhere((i) => i.id == id);
    await _persist(all);
  }

  Future<void> _persist(List<ExcelImport> imports) async {
    final json = jsonEncode(imports.map((i) => i.toJson()).toList());
    await _prefs.setString(_key, json);
  }
}

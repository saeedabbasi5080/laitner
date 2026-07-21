import 'package:equatable/equatable.dart';

class ExcelImportRow extends Equatable {
  const ExcelImportRow({
    required this.id,
    required this.front,
    required this.back,
    this.isAdded = false,
    this.addedAt,
  });

  final String id;
  final String front;
  final String back;
  final bool isAdded;
  final DateTime? addedAt;

  ExcelImportRow copyWith({
    String? id,
    String? front,
    String? back,
    bool? isAdded,
    DateTime? addedAt,
    bool clearAddedAt = false,
  }) {
    return ExcelImportRow(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      isAdded: isAdded ?? this.isAdded,
      addedAt: clearAddedAt ? null : (addedAt ?? this.addedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'isAdded': isAdded,
        'addedAt': addedAt?.toIso8601String(),
      };

  factory ExcelImportRow.fromJson(Map<String, dynamic> json) {
    return ExcelImportRow(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      isAdded: _readBool(json['isAdded']),
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : null,
    );
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  @override
  List<Object?> get props => [id, front, back, isAdded, addedAt];
}

class ExcelImport extends Equatable {
  const ExcelImport({
    required this.id,
    required this.spaceId,
    required this.fileName,
    required this.createdAt,
    required this.rows,
  });

  final String id;
  final String spaceId;
  final String fileName;
  final DateTime createdAt;
  final List<ExcelImportRow> rows;

  int get pendingCount => rows.where((r) => !r.isAdded).length;
  int get addedCount => rows.where((r) => r.isAdded).length;

  List<ExcelImportRow> get pendingRows =>
      rows.where((r) => !r.isAdded).toList();

  ExcelImport copyWith({
    String? id,
    String? spaceId,
    String? fileName,
    DateTime? createdAt,
    List<ExcelImportRow>? rows,
  }) {
    return ExcelImport(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      rows: rows ?? this.rows,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
        'rows': rows.map((r) => r.toJson()).toList(),
      };

  factory ExcelImport.fromJson(Map<String, dynamic> json) {
    return ExcelImport(
      id: json['id'] as String,
      spaceId: json['spaceId'] as String? ?? '',
      fileName: json['fileName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => ExcelImportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, spaceId, fileName, createdAt, rows];
}

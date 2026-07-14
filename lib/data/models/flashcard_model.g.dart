// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFlashcardModelCollection on Isar {
  IsarCollection<FlashcardModel> get flashcardModels => this.collection();
}

const FlashcardModelSchema = CollectionSchema(
  name: r'FlashcardModel',
  id: 429812019528624768,
  properties: {
    r'back': PropertySchema(
      id: 0,
      name: r'back',
      type: IsarType.string,
    ),
    r'box': PropertySchema(
      id: 1,
      name: r'box',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deckId': PropertySchema(
      id: 3,
      name: r'deckId',
      type: IsarType.string,
    ),
    r'front': PropertySchema(
      id: 4,
      name: r'front',
      type: IsarType.string,
    ),
    r'lastReviewed': PropertySchema(
      id: 5,
      name: r'lastReviewed',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 6,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _flashcardModelEstimateSize,
  serialize: _flashcardModelSerialize,
  deserialize: _flashcardModelDeserialize,
  deserializeProp: _flashcardModelDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'deckId': IndexSchema(
      id: -1182505463565197889,
      name: r'deckId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deckId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _flashcardModelGetId,
  getLinks: _flashcardModelGetLinks,
  attach: _flashcardModelAttach,
  version: '3.1.0+1',
);

int _flashcardModelEstimateSize(
  FlashcardModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.back.length * 3;
  bytesCount += 3 + object.deckId.length * 3;
  bytesCount += 3 + object.front.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _flashcardModelSerialize(
  FlashcardModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.back);
  writer.writeLong(offsets[1], object.box);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.deckId);
  writer.writeString(offsets[4], object.front);
  writer.writeDateTime(offsets[5], object.lastReviewed);
  writer.writeString(offsets[6], object.uuid);
}

FlashcardModel _flashcardModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FlashcardModel();
  object.back = reader.readString(offsets[0]);
  object.box = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.deckId = reader.readString(offsets[3]);
  object.front = reader.readString(offsets[4]);
  object.isarId = id;
  object.lastReviewed = reader.readDateTimeOrNull(offsets[5]);
  object.uuid = reader.readString(offsets[6]);
  return object;
}

P _flashcardModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _flashcardModelGetId(FlashcardModel object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _flashcardModelGetLinks(FlashcardModel object) {
  return [];
}

void _flashcardModelAttach(
    IsarCollection<dynamic> col, Id id, FlashcardModel object) {
  object.isarId = id;
}

extension FlashcardModelByIndex on IsarCollection<FlashcardModel> {
  Future<FlashcardModel?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  FlashcardModel? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<FlashcardModel?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<FlashcardModel?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(FlashcardModel object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(FlashcardModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<FlashcardModel> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<FlashcardModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension FlashcardModelQueryWhereSort
    on QueryBuilder<FlashcardModel, FlashcardModel, QWhere> {
  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FlashcardModelQueryWhere
    on QueryBuilder<FlashcardModel, FlashcardModel, QWhereClause> {
  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause>
      isarIdNotEqualTo(Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause>
      isarIdGreaterThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause>
      isarIdLessThan(Id isarId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause> deckIdEqualTo(
      String deckId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deckId',
        value: [deckId],
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterWhereClause>
      deckIdNotEqualTo(String deckId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckId',
              lower: [],
              upper: [deckId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckId',
              lower: [deckId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckId',
              lower: [deckId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deckId',
              lower: [],
              upper: [deckId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FlashcardModelQueryFilter
    on QueryBuilder<FlashcardModel, FlashcardModel, QFilterCondition> {
  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'back',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'back',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'back',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'back',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      backIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'back',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      boxEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'box',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      boxGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'box',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      boxLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'box',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      boxBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'box',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deckId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deckId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deckId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deckId',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      deckIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deckId',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'front',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'front',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'front',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'front',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      frontIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'front',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      isarIdEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastReviewed',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastReviewed',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReviewed',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReviewed',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReviewed',
        value: value,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      lastReviewedBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReviewed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension FlashcardModelQueryObject
    on QueryBuilder<FlashcardModel, FlashcardModel, QFilterCondition> {}

extension FlashcardModelQueryLinks
    on QueryBuilder<FlashcardModel, FlashcardModel, QFilterCondition> {}

extension FlashcardModelQuerySortBy
    on QueryBuilder<FlashcardModel, FlashcardModel, QSortBy> {
  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByBack() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByBackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByBox() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'box', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByBoxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'box', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByDeckId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckId', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      sortByDeckIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckId', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByFront() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByFrontDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      sortByLastReviewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewed', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      sortByLastReviewedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewed', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FlashcardModelQuerySortThenBy
    on QueryBuilder<FlashcardModel, FlashcardModel, QSortThenBy> {
  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByBack() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByBackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'back', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByBox() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'box', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByBoxDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'box', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByDeckId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckId', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      thenByDeckIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deckId', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByFront() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByFrontDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'front', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      thenByLastReviewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewed', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy>
      thenByLastReviewedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReviewed', Sort.desc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FlashcardModelQueryWhereDistinct
    on QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> {
  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> distinctByBack(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'back', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> distinctByBox() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'box');
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> distinctByDeckId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deckId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> distinctByFront(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'front', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct>
      distinctByLastReviewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReviewed');
    });
  }

  QueryBuilder<FlashcardModel, FlashcardModel, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension FlashcardModelQueryProperty
    on QueryBuilder<FlashcardModel, FlashcardModel, QQueryProperty> {
  QueryBuilder<FlashcardModel, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<FlashcardModel, String, QQueryOperations> backProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'back');
    });
  }

  QueryBuilder<FlashcardModel, int, QQueryOperations> boxProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'box');
    });
  }

  QueryBuilder<FlashcardModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FlashcardModel, String, QQueryOperations> deckIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deckId');
    });
  }

  QueryBuilder<FlashcardModel, String, QQueryOperations> frontProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'front');
    });
  }

  QueryBuilder<FlashcardModel, DateTime?, QQueryOperations>
      lastReviewedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReviewed');
    });
  }

  QueryBuilder<FlashcardModel, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}

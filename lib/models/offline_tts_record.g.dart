// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_tts_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOfflineTtsRecordCollection on Isar {
  IsarCollection<OfflineTtsRecord> get offlineTtsRecords => this.collection();
}

const OfflineTtsRecordSchema = CollectionSchema(
  name: r'OfflineTtsRecord',
  id: -4662430743908181725,
  properties: {
    r'bookChapterKey': PropertySchema(
      id: 0,
      name: r'bookChapterKey',
      type: IsarType.string,
    ),
    r'bookUuid': PropertySchema(
      id: 1,
      name: r'bookUuid',
      type: IsarType.string,
    ),
    r'chapterIndex': PropertySchema(
      id: 2,
      name: r'chapterIndex',
      type: IsarType.long,
    ),
    r'downloadedAt': PropertySchema(
      id: 3,
      name: r'downloadedAt',
      type: IsarType.dateTime,
    ),
    r'downloadedParagraphs': PropertySchema(
      id: 4,
      name: r'downloadedParagraphs',
      type: IsarType.long,
    ),
    r'isCompleted': PropertySchema(
      id: 5,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'speechRate': PropertySchema(
      id: 6,
      name: r'speechRate',
      type: IsarType.double,
    ),
    r'totalParagraphs': PropertySchema(
      id: 7,
      name: r'totalParagraphs',
      type: IsarType.long,
    ),
    r'totalSizeBytes': PropertySchema(
      id: 8,
      name: r'totalSizeBytes',
      type: IsarType.long,
    ),
    r'ttsProvider': PropertySchema(
      id: 9,
      name: r'ttsProvider',
      type: IsarType.string,
    ),
    r'voiceName': PropertySchema(
      id: 10,
      name: r'voiceName',
      type: IsarType.string,
    )
  },
  estimateSize: _offlineTtsRecordEstimateSize,
  serialize: _offlineTtsRecordSerialize,
  deserialize: _offlineTtsRecordDeserialize,
  deserializeProp: _offlineTtsRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'bookUuid': IndexSchema(
      id: -1177453174310852450,
      name: r'bookUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'bookUuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'chapterIndex': IndexSchema(
      id: 4711593575055231630,
      name: r'chapterIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'chapterIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'bookChapterKey': IndexSchema(
      id: -8976008240597728465,
      name: r'bookChapterKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'bookChapterKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _offlineTtsRecordGetId,
  getLinks: _offlineTtsRecordGetLinks,
  attach: _offlineTtsRecordAttach,
  version: '3.1.0+1',
);

int _offlineTtsRecordEstimateSize(
  OfflineTtsRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bookChapterKey.length * 3;
  bytesCount += 3 + object.bookUuid.length * 3;
  bytesCount += 3 + object.ttsProvider.length * 3;
  bytesCount += 3 + object.voiceName.length * 3;
  return bytesCount;
}

void _offlineTtsRecordSerialize(
  OfflineTtsRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bookChapterKey);
  writer.writeString(offsets[1], object.bookUuid);
  writer.writeLong(offsets[2], object.chapterIndex);
  writer.writeDateTime(offsets[3], object.downloadedAt);
  writer.writeLong(offsets[4], object.downloadedParagraphs);
  writer.writeBool(offsets[5], object.isCompleted);
  writer.writeDouble(offsets[6], object.speechRate);
  writer.writeLong(offsets[7], object.totalParagraphs);
  writer.writeLong(offsets[8], object.totalSizeBytes);
  writer.writeString(offsets[9], object.ttsProvider);
  writer.writeString(offsets[10], object.voiceName);
}

OfflineTtsRecord _offlineTtsRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OfflineTtsRecord();
  object.bookChapterKey = reader.readString(offsets[0]);
  object.bookUuid = reader.readString(offsets[1]);
  object.chapterIndex = reader.readLong(offsets[2]);
  object.downloadedAt = reader.readDateTime(offsets[3]);
  object.downloadedParagraphs = reader.readLong(offsets[4]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[5]);
  object.speechRate = reader.readDouble(offsets[6]);
  object.totalParagraphs = reader.readLong(offsets[7]);
  object.totalSizeBytes = reader.readLong(offsets[8]);
  object.ttsProvider = reader.readString(offsets[9]);
  object.voiceName = reader.readString(offsets[10]);
  return object;
}

P _offlineTtsRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _offlineTtsRecordGetId(OfflineTtsRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _offlineTtsRecordGetLinks(OfflineTtsRecord object) {
  return [];
}

void _offlineTtsRecordAttach(
    IsarCollection<dynamic> col, Id id, OfflineTtsRecord object) {
  object.id = id;
}

extension OfflineTtsRecordByIndex on IsarCollection<OfflineTtsRecord> {
  Future<OfflineTtsRecord?> getByBookChapterKey(String bookChapterKey) {
    return getByIndex(r'bookChapterKey', [bookChapterKey]);
  }

  OfflineTtsRecord? getByBookChapterKeySync(String bookChapterKey) {
    return getByIndexSync(r'bookChapterKey', [bookChapterKey]);
  }

  Future<bool> deleteByBookChapterKey(String bookChapterKey) {
    return deleteByIndex(r'bookChapterKey', [bookChapterKey]);
  }

  bool deleteByBookChapterKeySync(String bookChapterKey) {
    return deleteByIndexSync(r'bookChapterKey', [bookChapterKey]);
  }

  Future<List<OfflineTtsRecord?>> getAllByBookChapterKey(
      List<String> bookChapterKeyValues) {
    final values = bookChapterKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'bookChapterKey', values);
  }

  List<OfflineTtsRecord?> getAllByBookChapterKeySync(
      List<String> bookChapterKeyValues) {
    final values = bookChapterKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'bookChapterKey', values);
  }

  Future<int> deleteAllByBookChapterKey(List<String> bookChapterKeyValues) {
    final values = bookChapterKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'bookChapterKey', values);
  }

  int deleteAllByBookChapterKeySync(List<String> bookChapterKeyValues) {
    final values = bookChapterKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'bookChapterKey', values);
  }

  Future<Id> putByBookChapterKey(OfflineTtsRecord object) {
    return putByIndex(r'bookChapterKey', object);
  }

  Id putByBookChapterKeySync(OfflineTtsRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'bookChapterKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBookChapterKey(List<OfflineTtsRecord> objects) {
    return putAllByIndex(r'bookChapterKey', objects);
  }

  List<Id> putAllByBookChapterKeySync(List<OfflineTtsRecord> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'bookChapterKey', objects, saveLinks: saveLinks);
  }
}

extension OfflineTtsRecordQueryWhereSort
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QWhere> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhere>
      anyChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'chapterIndex'),
      );
    });
  }
}

extension OfflineTtsRecordQueryWhere
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QWhereClause> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      bookUuidEqualTo(String bookUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'bookUuid',
        value: [bookUuid],
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      bookUuidNotEqualTo(String bookUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookUuid',
              lower: [],
              upper: [bookUuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookUuid',
              lower: [bookUuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookUuid',
              lower: [bookUuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookUuid',
              lower: [],
              upper: [bookUuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      chapterIndexEqualTo(int chapterIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chapterIndex',
        value: [chapterIndex],
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      chapterIndexNotEqualTo(int chapterIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chapterIndex',
              lower: [],
              upper: [chapterIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chapterIndex',
              lower: [chapterIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chapterIndex',
              lower: [chapterIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chapterIndex',
              lower: [],
              upper: [chapterIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      chapterIndexGreaterThan(
    int chapterIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chapterIndex',
        lower: [chapterIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      chapterIndexLessThan(
    int chapterIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chapterIndex',
        lower: [],
        upper: [chapterIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      chapterIndexBetween(
    int lowerChapterIndex,
    int upperChapterIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chapterIndex',
        lower: [lowerChapterIndex],
        includeLower: includeLower,
        upper: [upperChapterIndex],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      bookChapterKeyEqualTo(String bookChapterKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'bookChapterKey',
        value: [bookChapterKey],
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterWhereClause>
      bookChapterKeyNotEqualTo(String bookChapterKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookChapterKey',
              lower: [],
              upper: [bookChapterKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookChapterKey',
              lower: [bookChapterKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookChapterKey',
              lower: [bookChapterKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'bookChapterKey',
              lower: [],
              upper: [bookChapterKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OfflineTtsRecordQueryFilter
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QFilterCondition> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookChapterKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookChapterKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookChapterKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookChapterKey',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookChapterKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookChapterKey',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      bookUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      chapterIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      chapterIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      chapterIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      chapterIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapterIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedParagraphsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadedParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedParagraphsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadedParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedParagraphsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadedParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      downloadedParagraphsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadedParagraphs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      speechRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speechRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      speechRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speechRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      speechRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speechRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      speechRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speechRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalParagraphsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalParagraphsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalParagraphsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalParagraphs',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalParagraphsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalParagraphs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalSizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalSizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalSizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalSizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      totalSizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalSizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ttsProvider',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ttsProvider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ttsProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      ttsProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ttsProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'voiceName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'voiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'voiceName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'voiceName',
        value: '',
      ));
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterFilterCondition>
      voiceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'voiceName',
        value: '',
      ));
    });
  }
}

extension OfflineTtsRecordQueryObject
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QFilterCondition> {}

extension OfflineTtsRecordQueryLinks
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QFilterCondition> {}

extension OfflineTtsRecordQuerySortBy
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QSortBy> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByBookChapterKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookChapterKey', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByBookChapterKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookChapterKey', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByBookUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookUuid', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByBookUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookUuid', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByChapterIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByDownloadedParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedParagraphs', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByDownloadedParagraphsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedParagraphs', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortBySpeechRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTotalParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalParagraphs', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTotalParagraphsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalParagraphs', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTotalSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTotalSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTtsProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByTtsProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByVoiceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'voiceName', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      sortByVoiceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'voiceName', Sort.desc);
    });
  }
}

extension OfflineTtsRecordQuerySortThenBy
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QSortThenBy> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByBookChapterKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookChapterKey', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByBookChapterKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookChapterKey', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByBookUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookUuid', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByBookUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookUuid', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterIndex', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByChapterIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterIndex', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByDownloadedParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedParagraphs', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByDownloadedParagraphsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedParagraphs', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenBySpeechRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTotalParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalParagraphs', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTotalParagraphsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalParagraphs', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTotalSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTotalSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTtsProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByTtsProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.desc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByVoiceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'voiceName', Sort.asc);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QAfterSortBy>
      thenByVoiceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'voiceName', Sort.desc);
    });
  }
}

extension OfflineTtsRecordQueryWhereDistinct
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct> {
  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByBookChapterKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookChapterKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByBookUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapterIndex');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedAt');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByDownloadedParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedParagraphs');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speechRate');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByTotalParagraphs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalParagraphs');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByTotalSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalSizeBytes');
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByTtsProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ttsProvider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QDistinct>
      distinctByVoiceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'voiceName', caseSensitive: caseSensitive);
    });
  }
}

extension OfflineTtsRecordQueryProperty
    on QueryBuilder<OfflineTtsRecord, OfflineTtsRecord, QQueryProperty> {
  QueryBuilder<OfflineTtsRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OfflineTtsRecord, String, QQueryOperations>
      bookChapterKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookChapterKey');
    });
  }

  QueryBuilder<OfflineTtsRecord, String, QQueryOperations> bookUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookUuid');
    });
  }

  QueryBuilder<OfflineTtsRecord, int, QQueryOperations> chapterIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapterIndex');
    });
  }

  QueryBuilder<OfflineTtsRecord, DateTime, QQueryOperations>
      downloadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedAt');
    });
  }

  QueryBuilder<OfflineTtsRecord, int, QQueryOperations>
      downloadedParagraphsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedParagraphs');
    });
  }

  QueryBuilder<OfflineTtsRecord, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<OfflineTtsRecord, double, QQueryOperations>
      speechRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speechRate');
    });
  }

  QueryBuilder<OfflineTtsRecord, int, QQueryOperations>
      totalParagraphsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalParagraphs');
    });
  }

  QueryBuilder<OfflineTtsRecord, int, QQueryOperations>
      totalSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalSizeBytes');
    });
  }

  QueryBuilder<OfflineTtsRecord, String, QQueryOperations>
      ttsProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ttsProvider');
    });
  }

  QueryBuilder<OfflineTtsRecord, String, QQueryOperations> voiceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'voiceName');
    });
  }
}

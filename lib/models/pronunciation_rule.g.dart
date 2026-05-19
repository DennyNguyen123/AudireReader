// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pronunciation_rule.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPronunciationRuleCollection on Isar {
  IsarCollection<PronunciationRule> get pronunciationRules => this.collection();
}

const PronunciationRuleSchema = CollectionSchema(
  name: r'PronunciationRule',
  id: -1417294750764375786,
  properties: {
    r'active': PropertySchema(
      id: 0,
      name: r'active',
      type: IsarType.bool,
    ),
    r'isRegex': PropertySchema(
      id: 1,
      name: r'isRegex',
      type: IsarType.bool,
    ),
    r'replacement': PropertySchema(
      id: 2,
      name: r'replacement',
      type: IsarType.string,
    ),
    r'target': PropertySchema(
      id: 3,
      name: r'target',
      type: IsarType.string,
    )
  },
  estimateSize: _pronunciationRuleEstimateSize,
  serialize: _pronunciationRuleSerialize,
  deserialize: _pronunciationRuleDeserialize,
  deserializeProp: _pronunciationRuleDeserializeProp,
  idName: r'id',
  indexes: {
    r'target': IndexSchema(
      id: -279045078341725161,
      name: r'target',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'target',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _pronunciationRuleGetId,
  getLinks: _pronunciationRuleGetLinks,
  attach: _pronunciationRuleAttach,
  version: '3.1.0+1',
);

int _pronunciationRuleEstimateSize(
  PronunciationRule object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.replacement.length * 3;
  bytesCount += 3 + object.target.length * 3;
  return bytesCount;
}

void _pronunciationRuleSerialize(
  PronunciationRule object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.active);
  writer.writeBool(offsets[1], object.isRegex);
  writer.writeString(offsets[2], object.replacement);
  writer.writeString(offsets[3], object.target);
}

PronunciationRule _pronunciationRuleDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PronunciationRule();
  object.active = reader.readBool(offsets[0]);
  object.id = id;
  object.isRegex = reader.readBool(offsets[1]);
  object.replacement = reader.readString(offsets[2]);
  object.target = reader.readString(offsets[3]);
  return object;
}

P _pronunciationRuleDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pronunciationRuleGetId(PronunciationRule object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pronunciationRuleGetLinks(
    PronunciationRule object) {
  return [];
}

void _pronunciationRuleAttach(
    IsarCollection<dynamic> col, Id id, PronunciationRule object) {
  object.id = id;
}

extension PronunciationRuleByIndex on IsarCollection<PronunciationRule> {
  Future<PronunciationRule?> getByTarget(String target) {
    return getByIndex(r'target', [target]);
  }

  PronunciationRule? getByTargetSync(String target) {
    return getByIndexSync(r'target', [target]);
  }

  Future<bool> deleteByTarget(String target) {
    return deleteByIndex(r'target', [target]);
  }

  bool deleteByTargetSync(String target) {
    return deleteByIndexSync(r'target', [target]);
  }

  Future<List<PronunciationRule?>> getAllByTarget(List<String> targetValues) {
    final values = targetValues.map((e) => [e]).toList();
    return getAllByIndex(r'target', values);
  }

  List<PronunciationRule?> getAllByTargetSync(List<String> targetValues) {
    final values = targetValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'target', values);
  }

  Future<int> deleteAllByTarget(List<String> targetValues) {
    final values = targetValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'target', values);
  }

  int deleteAllByTargetSync(List<String> targetValues) {
    final values = targetValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'target', values);
  }

  Future<Id> putByTarget(PronunciationRule object) {
    return putByIndex(r'target', object);
  }

  Id putByTargetSync(PronunciationRule object, {bool saveLinks = true}) {
    return putByIndexSync(r'target', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTarget(List<PronunciationRule> objects) {
    return putAllByIndex(r'target', objects);
  }

  List<Id> putAllByTargetSync(List<PronunciationRule> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'target', objects, saveLinks: saveLinks);
  }
}

extension PronunciationRuleQueryWhereSort
    on QueryBuilder<PronunciationRule, PronunciationRule, QWhere> {
  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PronunciationRuleQueryWhere
    on QueryBuilder<PronunciationRule, PronunciationRule, QWhereClause> {
  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
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

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      targetEqualTo(String target) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'target',
        value: [target],
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterWhereClause>
      targetNotEqualTo(String target) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'target',
              lower: [],
              upper: [target],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'target',
              lower: [target],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'target',
              lower: [target],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'target',
              lower: [],
              upper: [target],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PronunciationRuleQueryFilter
    on QueryBuilder<PronunciationRule, PronunciationRule, QFilterCondition> {
  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      activeEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'active',
        value: value,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
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

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
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

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
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

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      isRegexEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRegex',
        value: value,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replacement',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'replacement',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'replacement',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replacement',
        value: '',
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      replacementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'replacement',
        value: '',
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'target',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'target',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'target',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'target',
        value: '',
      ));
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterFilterCondition>
      targetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'target',
        value: '',
      ));
    });
  }
}

extension PronunciationRuleQueryObject
    on QueryBuilder<PronunciationRule, PronunciationRule, QFilterCondition> {}

extension PronunciationRuleQueryLinks
    on QueryBuilder<PronunciationRule, PronunciationRule, QFilterCondition> {}

extension PronunciationRuleQuerySortBy
    on QueryBuilder<PronunciationRule, PronunciationRule, QSortBy> {
  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByIsRegex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRegex', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByIsRegexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRegex', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByReplacement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacement', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByReplacementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacement', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      sortByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }
}

extension PronunciationRuleQuerySortThenBy
    on QueryBuilder<PronunciationRule, PronunciationRule, QSortThenBy> {
  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'active', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByIsRegex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRegex', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByIsRegexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRegex', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByReplacement() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacement', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByReplacementDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replacement', Sort.desc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.asc);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QAfterSortBy>
      thenByTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'target', Sort.desc);
    });
  }
}

extension PronunciationRuleQueryWhereDistinct
    on QueryBuilder<PronunciationRule, PronunciationRule, QDistinct> {
  QueryBuilder<PronunciationRule, PronunciationRule, QDistinct>
      distinctByActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'active');
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QDistinct>
      distinctByIsRegex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRegex');
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QDistinct>
      distinctByReplacement({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replacement', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PronunciationRule, PronunciationRule, QDistinct>
      distinctByTarget({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'target', caseSensitive: caseSensitive);
    });
  }
}

extension PronunciationRuleQueryProperty
    on QueryBuilder<PronunciationRule, PronunciationRule, QQueryProperty> {
  QueryBuilder<PronunciationRule, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PronunciationRule, bool, QQueryOperations> activeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'active');
    });
  }

  QueryBuilder<PronunciationRule, bool, QQueryOperations> isRegexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRegex');
    });
  }

  QueryBuilder<PronunciationRule, String, QQueryOperations>
      replacementProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replacement');
    });
  }

  QueryBuilder<PronunciationRule, String, QQueryOperations> targetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'target');
    });
  }
}

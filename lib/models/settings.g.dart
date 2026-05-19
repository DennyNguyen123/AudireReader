// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsCollection on Isar {
  IsarCollection<AppSettings> get appSettings => this.collection();
}

const AppSettingsSchema = CollectionSchema(
  name: r'AppSettings',
  id: -5633561779022347008,
  properties: {
    r'autoCheckUpdate': PropertySchema(
      id: 0,
      name: r'autoCheckUpdate',
      type: IsarType.bool,
    ),
    r'bossKeyAction': PropertySchema(
      id: 1,
      name: r'bossKeyAction',
      type: IsarType.string,
    ),
    r'fontFamily': PropertySchema(
      id: 2,
      name: r'fontFamily',
      type: IsarType.string,
    ),
    r'fontSize': PropertySchema(
      id: 3,
      name: r'fontSize',
      type: IsarType.double,
    ),
    r'hotkeyBossKey': PropertySchema(
      id: 4,
      name: r'hotkeyBossKey',
      type: IsarType.string,
    ),
    r'hotkeyNextChapter': PropertySchema(
      id: 5,
      name: r'hotkeyNextChapter',
      type: IsarType.string,
    ),
    r'hotkeyNextParagraph': PropertySchema(
      id: 6,
      name: r'hotkeyNextParagraph',
      type: IsarType.string,
    ),
    r'hotkeyOpenChapter': PropertySchema(
      id: 7,
      name: r'hotkeyOpenChapter',
      type: IsarType.string,
    ),
    r'hotkeyOpenSetting': PropertySchema(
      id: 8,
      name: r'hotkeyOpenSetting',
      type: IsarType.string,
    ),
    r'hotkeyPlayPauseTts': PropertySchema(
      id: 9,
      name: r'hotkeyPlayPauseTts',
      type: IsarType.string,
    ),
    r'hotkeyPrevChapter': PropertySchema(
      id: 10,
      name: r'hotkeyPrevChapter',
      type: IsarType.string,
    ),
    r'hotkeyPrevParagraph': PropertySchema(
      id: 11,
      name: r'hotkeyPrevParagraph',
      type: IsarType.string,
    ),
    r'openLastReadOnLaunch': PropertySchema(
      id: 12,
      name: r'openLastReadOnLaunch',
      type: IsarType.bool,
    ),
    r'selectedVoiceLocale': PropertySchema(
      id: 13,
      name: r'selectedVoiceLocale',
      type: IsarType.string,
    ),
    r'selectedVoiceName': PropertySchema(
      id: 14,
      name: r'selectedVoiceName',
      type: IsarType.string,
    ),
    r'speechRate': PropertySchema(
      id: 15,
      name: r'speechRate',
      type: IsarType.double,
    ),
    r'themeMode': PropertySchema(
      id: 16,
      name: r'themeMode',
      type: IsarType.string,
    ),
    r'ttsProvider': PropertySchema(
      id: 17,
      name: r'ttsProvider',
      type: IsarType.string,
    ),
    r'webDavEnabled': PropertySchema(
      id: 18,
      name: r'webDavEnabled',
      type: IsarType.bool,
    ),
    r'webDavLastSync': PropertySchema(
      id: 19,
      name: r'webDavLastSync',
      type: IsarType.dateTime,
    ),
    r'webDavPassword': PropertySchema(
      id: 20,
      name: r'webDavPassword',
      type: IsarType.string,
    ),
    r'webDavUrl': PropertySchema(
      id: 21,
      name: r'webDavUrl',
      type: IsarType.string,
    ),
    r'webDavUsername': PropertySchema(
      id: 22,
      name: r'webDavUsername',
      type: IsarType.string,
    )
  },
  estimateSize: _appSettingsEstimateSize,
  serialize: _appSettingsSerialize,
  deserialize: _appSettingsDeserialize,
  deserializeProp: _appSettingsDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsGetId,
  getLinks: _appSettingsGetLinks,
  attach: _appSettingsAttach,
  version: '3.1.0+1',
);

int _appSettingsEstimateSize(
  AppSettings object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bossKeyAction.length * 3;
  bytesCount += 3 + object.fontFamily.length * 3;
  bytesCount += 3 + object.hotkeyBossKey.length * 3;
  bytesCount += 3 + object.hotkeyNextChapter.length * 3;
  bytesCount += 3 + object.hotkeyNextParagraph.length * 3;
  bytesCount += 3 + object.hotkeyOpenChapter.length * 3;
  bytesCount += 3 + object.hotkeyOpenSetting.length * 3;
  bytesCount += 3 + object.hotkeyPlayPauseTts.length * 3;
  bytesCount += 3 + object.hotkeyPrevChapter.length * 3;
  bytesCount += 3 + object.hotkeyPrevParagraph.length * 3;
  {
    final value = object.selectedVoiceLocale;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.selectedVoiceName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.themeMode.length * 3;
  bytesCount += 3 + object.ttsProvider.length * 3;
  bytesCount += 3 + object.webDavPassword.length * 3;
  bytesCount += 3 + object.webDavUrl.length * 3;
  bytesCount += 3 + object.webDavUsername.length * 3;
  return bytesCount;
}

void _appSettingsSerialize(
  AppSettings object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoCheckUpdate);
  writer.writeString(offsets[1], object.bossKeyAction);
  writer.writeString(offsets[2], object.fontFamily);
  writer.writeDouble(offsets[3], object.fontSize);
  writer.writeString(offsets[4], object.hotkeyBossKey);
  writer.writeString(offsets[5], object.hotkeyNextChapter);
  writer.writeString(offsets[6], object.hotkeyNextParagraph);
  writer.writeString(offsets[7], object.hotkeyOpenChapter);
  writer.writeString(offsets[8], object.hotkeyOpenSetting);
  writer.writeString(offsets[9], object.hotkeyPlayPauseTts);
  writer.writeString(offsets[10], object.hotkeyPrevChapter);
  writer.writeString(offsets[11], object.hotkeyPrevParagraph);
  writer.writeBool(offsets[12], object.openLastReadOnLaunch);
  writer.writeString(offsets[13], object.selectedVoiceLocale);
  writer.writeString(offsets[14], object.selectedVoiceName);
  writer.writeDouble(offsets[15], object.speechRate);
  writer.writeString(offsets[16], object.themeMode);
  writer.writeString(offsets[17], object.ttsProvider);
  writer.writeBool(offsets[18], object.webDavEnabled);
  writer.writeDateTime(offsets[19], object.webDavLastSync);
  writer.writeString(offsets[20], object.webDavPassword);
  writer.writeString(offsets[21], object.webDavUrl);
  writer.writeString(offsets[22], object.webDavUsername);
}

AppSettings _appSettingsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettings();
  object.autoCheckUpdate = reader.readBool(offsets[0]);
  object.bossKeyAction = reader.readString(offsets[1]);
  object.fontFamily = reader.readString(offsets[2]);
  object.fontSize = reader.readDouble(offsets[3]);
  object.hotkeyBossKey = reader.readString(offsets[4]);
  object.hotkeyNextChapter = reader.readString(offsets[5]);
  object.hotkeyNextParagraph = reader.readString(offsets[6]);
  object.hotkeyOpenChapter = reader.readString(offsets[7]);
  object.hotkeyOpenSetting = reader.readString(offsets[8]);
  object.hotkeyPlayPauseTts = reader.readString(offsets[9]);
  object.hotkeyPrevChapter = reader.readString(offsets[10]);
  object.hotkeyPrevParagraph = reader.readString(offsets[11]);
  object.id = id;
  object.openLastReadOnLaunch = reader.readBool(offsets[12]);
  object.selectedVoiceLocale = reader.readStringOrNull(offsets[13]);
  object.selectedVoiceName = reader.readStringOrNull(offsets[14]);
  object.speechRate = reader.readDouble(offsets[15]);
  object.themeMode = reader.readString(offsets[16]);
  object.ttsProvider = reader.readString(offsets[17]);
  object.webDavEnabled = reader.readBool(offsets[18]);
  object.webDavLastSync = reader.readDateTimeOrNull(offsets[19]);
  object.webDavPassword = reader.readString(offsets[20]);
  object.webDavUrl = reader.readString(offsets[21]);
  object.webDavUsername = reader.readString(offsets[22]);
  return object;
}

P _appSettingsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readBool(offset)) as P;
    case 19:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsGetId(AppSettings object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appSettingsGetLinks(AppSettings object) {
  return [];
}

void _appSettingsAttach(
    IsarCollection<dynamic> col, Id id, AppSettings object) {
  object.id = id;
}

extension AppSettingsQueryWhereSort
    on QueryBuilder<AppSettings, AppSettings, QWhere> {
  QueryBuilder<AppSettings, AppSettings, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsQueryWhere
    on QueryBuilder<AppSettings, AppSettings, QWhereClause> {
  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterWhereClause> idBetween(
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
}

extension AppSettingsQueryFilter
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {
  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      autoCheckUpdateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoCheckUpdate',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bossKeyAction',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bossKeyAction',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bossKeyAction',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bossKeyAction',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      bossKeyActionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bossKeyAction',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontFamily',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fontFamily',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontFamilyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> fontSizeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontSizeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      fontSizeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> fontSizeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyBossKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyBossKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyBossKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyBossKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyBossKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyBossKey',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyNextChapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyNextChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyNextChapter',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyNextChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextChapterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyNextChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyNextParagraph',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyNextParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyNextParagraph',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyNextParagraph',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyNextParagraphIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyNextParagraph',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyOpenChapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyOpenChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyOpenChapter',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyOpenChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenChapterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyOpenChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyOpenSetting',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyOpenSetting',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyOpenSetting',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyOpenSetting',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyOpenSettingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyOpenSetting',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyPlayPauseTts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyPlayPauseTts',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyPlayPauseTts',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPlayPauseTts',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPlayPauseTtsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyPlayPauseTts',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyPrevChapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyPrevChapter',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyPrevChapter',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPrevChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevChapterIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyPrevChapter',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hotkeyPrevParagraph',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'hotkeyPrevParagraph',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'hotkeyPrevParagraph',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hotkeyPrevParagraph',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      hotkeyPrevParagraphIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'hotkeyPrevParagraph',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      openLastReadOnLaunchEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openLastReadOnLaunch',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedVoiceLocale',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedVoiceLocale',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedVoiceLocale',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedVoiceLocale',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedVoiceLocale',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedVoiceLocale',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceLocaleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedVoiceLocale',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedVoiceName',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedVoiceName',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedVoiceName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedVoiceName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedVoiceName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedVoiceName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      selectedVoiceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedVoiceName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'themeMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'themeMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'themeMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeMode',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      themeModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'themeMode',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
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

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      ttsProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ttsProvider',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      ttsProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ttsProvider',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      ttsProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ttsProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      ttsProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ttsProvider',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavEnabled',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'webDavLastSync',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'webDavLastSync',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavLastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'webDavLastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'webDavLastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavLastSyncBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'webDavLastSync',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'webDavPassword',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'webDavPassword',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'webDavPassword',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavPassword',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavPasswordIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'webDavPassword',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'webDavUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'webDavUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'webDavUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'webDavUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'webDavUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'webDavUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'webDavUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'webDavUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterFilterCondition>
      webDavUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'webDavUsername',
        value: '',
      ));
    });
  }
}

extension AppSettingsQueryObject
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {}

extension AppSettingsQueryLinks
    on QueryBuilder<AppSettings, AppSettings, QFilterCondition> {}

extension AppSettingsQuerySortBy
    on QueryBuilder<AppSettings, AppSettings, QSortBy> {
  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByAutoCheckUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCheckUpdate', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByAutoCheckUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCheckUpdate', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByBossKeyAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bossKeyAction', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByBossKeyActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bossKeyAction', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByFontFamily() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontFamily', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByFontFamilyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontFamily', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontSize', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByFontSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontSize', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByHotkeyBossKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyBossKey', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyBossKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyBossKey', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyNextChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyNextChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyNextParagraph() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextParagraph', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyNextParagraphDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextParagraph', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyOpenChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyOpenChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyOpenSetting() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenSetting', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyOpenSettingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenSetting', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPlayPauseTts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPlayPauseTts', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPlayPauseTtsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPlayPauseTts', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPrevChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPrevChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPrevParagraph() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevParagraph', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByHotkeyPrevParagraphDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevParagraph', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByOpenLastReadOnLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openLastReadOnLaunch', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByOpenLastReadOnLaunchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openLastReadOnLaunch', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortBySelectedVoiceLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceLocale', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortBySelectedVoiceLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceLocale', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortBySelectedVoiceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceName', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortBySelectedVoiceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceName', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortBySpeechRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTtsProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByTtsProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByWebDavEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavLastSync', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByWebDavLastSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavLastSync', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavPassword', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByWebDavPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavPassword', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> sortByWebDavUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUsername', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      sortByWebDavUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUsername', Sort.desc);
    });
  }
}

extension AppSettingsQuerySortThenBy
    on QueryBuilder<AppSettings, AppSettings, QSortThenBy> {
  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByAutoCheckUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCheckUpdate', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByAutoCheckUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoCheckUpdate', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByBossKeyAction() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bossKeyAction', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByBossKeyActionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bossKeyAction', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByFontFamily() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontFamily', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByFontFamilyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontFamily', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontSize', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByFontSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fontSize', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByHotkeyBossKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyBossKey', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyBossKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyBossKey', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyNextChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyNextChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyNextParagraph() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextParagraph', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyNextParagraphDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyNextParagraph', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyOpenChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyOpenChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyOpenSetting() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenSetting', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyOpenSettingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyOpenSetting', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPlayPauseTts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPlayPauseTts', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPlayPauseTtsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPlayPauseTts', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPrevChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevChapter', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPrevChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevChapter', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPrevParagraph() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevParagraph', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByHotkeyPrevParagraphDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hotkeyPrevParagraph', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByOpenLastReadOnLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openLastReadOnLaunch', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByOpenLastReadOnLaunchDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openLastReadOnLaunch', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenBySelectedVoiceLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceLocale', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenBySelectedVoiceLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceLocale', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenBySelectedVoiceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceName', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenBySelectedVoiceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedVoiceName', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenBySpeechRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speechRate', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByThemeMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByThemeModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeMode', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTtsProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByTtsProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttsProvider', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavEnabled', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByWebDavEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavEnabled', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavLastSync', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByWebDavLastSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavLastSync', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavPassword() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavPassword', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByWebDavPasswordDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavPassword', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUrl', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUrl', Sort.desc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy> thenByWebDavUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUsername', Sort.asc);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QAfterSortBy>
      thenByWebDavUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'webDavUsername', Sort.desc);
    });
  }
}

extension AppSettingsQueryWhereDistinct
    on QueryBuilder<AppSettings, AppSettings, QDistinct> {
  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctByAutoCheckUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoCheckUpdate');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByBossKeyAction(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bossKeyAction',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByFontFamily(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fontFamily', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByFontSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fontSize');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByHotkeyBossKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyBossKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByHotkeyNextChapter(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyNextChapter',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctByHotkeyNextParagraph({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyNextParagraph',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByHotkeyOpenChapter(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyOpenChapter',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByHotkeyOpenSetting(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyOpenSetting',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctByHotkeyPlayPauseTts({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyPlayPauseTts',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByHotkeyPrevChapter(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyPrevChapter',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctByHotkeyPrevParagraph({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hotkeyPrevParagraph',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctByOpenLastReadOnLaunch() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openLastReadOnLaunch');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct>
      distinctBySelectedVoiceLocale({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedVoiceLocale',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctBySelectedVoiceName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedVoiceName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctBySpeechRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speechRate');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByThemeMode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeMode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByTtsProvider(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ttsProvider', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByWebDavEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'webDavEnabled');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByWebDavLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'webDavLastSync');
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByWebDavPassword(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'webDavPassword',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByWebDavUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'webDavUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettings, AppSettings, QDistinct> distinctByWebDavUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'webDavUsername',
          caseSensitive: caseSensitive);
    });
  }
}

extension AppSettingsQueryProperty
    on QueryBuilder<AppSettings, AppSettings, QQueryProperty> {
  QueryBuilder<AppSettings, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations> autoCheckUpdateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoCheckUpdate');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> bossKeyActionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bossKeyAction');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> fontFamilyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fontFamily');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> fontSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fontSize');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> hotkeyBossKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyBossKey');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyNextChapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyNextChapter');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyNextParagraphProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyNextParagraph');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyOpenChapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyOpenChapter');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyOpenSettingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyOpenSetting');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyPlayPauseTtsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyPlayPauseTts');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyPrevChapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyPrevChapter');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations>
      hotkeyPrevParagraphProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hotkeyPrevParagraph');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations>
      openLastReadOnLaunchProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openLastReadOnLaunch');
    });
  }

  QueryBuilder<AppSettings, String?, QQueryOperations>
      selectedVoiceLocaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedVoiceLocale');
    });
  }

  QueryBuilder<AppSettings, String?, QQueryOperations>
      selectedVoiceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedVoiceName');
    });
  }

  QueryBuilder<AppSettings, double, QQueryOperations> speechRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speechRate');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> themeModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeMode');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> ttsProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ttsProvider');
    });
  }

  QueryBuilder<AppSettings, bool, QQueryOperations> webDavEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'webDavEnabled');
    });
  }

  QueryBuilder<AppSettings, DateTime?, QQueryOperations>
      webDavLastSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'webDavLastSync');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> webDavPasswordProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'webDavPassword');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> webDavUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'webDavUrl');
    });
  }

  QueryBuilder<AppSettings, String, QQueryOperations> webDavUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'webDavUsername');
    });
  }
}

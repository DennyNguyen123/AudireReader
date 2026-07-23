// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Book {
  int? get id => throw _privateConstructorUsedError;
  String get uuid => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  String? get coverPath => throw _privateConstructorUsedError;
  int get totalChapters => throw _privateConstructorUsedError;
  int get dateAdded => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BookCopyWith<Book> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) then) =
      _$BookCopyWithImpl<$Res, Book>;
  @useResult
  $Res call(
      {int? id,
      String uuid,
      String title,
      String author,
      String? coverPath,
      int totalChapters,
      int dateAdded,
      String status,
      List<String> tags});
}

/// @nodoc
class _$BookCopyWithImpl<$Res, $Val extends Book>
    implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? uuid = null,
    Object? title = null,
    Object? author = null,
    Object? coverPath = freezed,
    Object? totalChapters = null,
    Object? dateAdded = null,
    Object? status = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      coverPath: freezed == coverPath
          ? _value.coverPath
          : coverPath // ignore: cast_nullable_to_non_nullable
              as String?,
      totalChapters: null == totalChapters
          ? _value.totalChapters
          : totalChapters // ignore: cast_nullable_to_non_nullable
              as int,
      dateAdded: null == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookImplCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$BookImplCopyWith(
          _$BookImpl value, $Res Function(_$BookImpl) then) =
      __$$BookImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String uuid,
      String title,
      String author,
      String? coverPath,
      int totalChapters,
      int dateAdded,
      String status,
      List<String> tags});
}

/// @nodoc
class __$$BookImplCopyWithImpl<$Res>
    extends _$BookCopyWithImpl<$Res, _$BookImpl>
    implements _$$BookImplCopyWith<$Res> {
  __$$BookImplCopyWithImpl(_$BookImpl _value, $Res Function(_$BookImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? uuid = null,
    Object? title = null,
    Object? author = null,
    Object? coverPath = freezed,
    Object? totalChapters = null,
    Object? dateAdded = null,
    Object? status = null,
    Object? tags = null,
  }) {
    return _then(_$BookImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      coverPath: freezed == coverPath
          ? _value.coverPath
          : coverPath // ignore: cast_nullable_to_non_nullable
              as String?,
      totalChapters: null == totalChapters
          ? _value.totalChapters
          : totalChapters // ignore: cast_nullable_to_non_nullable
              as int,
      dateAdded: null == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$BookImpl implements _Book {
  const _$BookImpl(
      {this.id,
      required this.uuid,
      required this.title,
      required this.author,
      this.coverPath,
      required this.totalChapters,
      required this.dateAdded,
      required this.status,
      required final List<String> tags})
      : _tags = tags;

  @override
  final int? id;
  @override
  final String uuid;
  @override
  final String title;
  @override
  final String author;
  @override
  final String? coverPath;
  @override
  final int totalChapters;
  @override
  final int dateAdded;
  @override
  final String status;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'Book(id: $id, uuid: $uuid, title: $title, author: $author, coverPath: $coverPath, totalChapters: $totalChapters, dateAdded: $dateAdded, status: $status, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.coverPath, coverPath) ||
                other.coverPath == coverPath) &&
            (identical(other.totalChapters, totalChapters) ||
                other.totalChapters == totalChapters) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      uuid,
      title,
      author,
      coverPath,
      totalChapters,
      dateAdded,
      status,
      const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      __$$BookImplCopyWithImpl<_$BookImpl>(this, _$identity);
}

abstract class _Book implements Book {
  const factory _Book(
      {final int? id,
      required final String uuid,
      required final String title,
      required final String author,
      final String? coverPath,
      required final int totalChapters,
      required final int dateAdded,
      required final String status,
      required final List<String> tags}) = _$BookImpl;

  @override
  int? get id;
  @override
  String get uuid;
  @override
  String get title;
  @override
  String get author;
  @override
  String? get coverPath;
  @override
  int get totalChapters;
  @override
  int get dateAdded;
  @override
  String get status;
  @override
  List<String> get tags;
  @override
  @JsonKey(ignore: true)
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Chapter {
  int? get id => throw _privateConstructorUsedError;
  String get bookUuid => throw _privateConstructorUsedError;
  int get chapterIndex => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<String> get paragraphs => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChapterCopyWith<Chapter> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChapterCopyWith<$Res> {
  factory $ChapterCopyWith(Chapter value, $Res Function(Chapter) then) =
      _$ChapterCopyWithImpl<$Res, Chapter>;
  @useResult
  $Res call(
      {int? id,
      String bookUuid,
      int chapterIndex,
      String title,
      List<String> paragraphs});
}

/// @nodoc
class _$ChapterCopyWithImpl<$Res, $Val extends Chapter>
    implements $ChapterCopyWith<$Res> {
  _$ChapterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? title = null,
    Object? paragraphs = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookUuid: null == bookUuid
          ? _value.bookUuid
          : bookUuid // ignore: cast_nullable_to_non_nullable
              as String,
      chapterIndex: null == chapterIndex
          ? _value.chapterIndex
          : chapterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      paragraphs: null == paragraphs
          ? _value.paragraphs
          : paragraphs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChapterImplCopyWith<$Res> implements $ChapterCopyWith<$Res> {
  factory _$$ChapterImplCopyWith(
          _$ChapterImpl value, $Res Function(_$ChapterImpl) then) =
      __$$ChapterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String bookUuid,
      int chapterIndex,
      String title,
      List<String> paragraphs});
}

/// @nodoc
class __$$ChapterImplCopyWithImpl<$Res>
    extends _$ChapterCopyWithImpl<$Res, _$ChapterImpl>
    implements _$$ChapterImplCopyWith<$Res> {
  __$$ChapterImplCopyWithImpl(
      _$ChapterImpl _value, $Res Function(_$ChapterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? title = null,
    Object? paragraphs = null,
  }) {
    return _then(_$ChapterImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookUuid: null == bookUuid
          ? _value.bookUuid
          : bookUuid // ignore: cast_nullable_to_non_nullable
              as String,
      chapterIndex: null == chapterIndex
          ? _value.chapterIndex
          : chapterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      paragraphs: null == paragraphs
          ? _value._paragraphs
          : paragraphs // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$ChapterImpl implements _Chapter {
  const _$ChapterImpl(
      {this.id,
      required this.bookUuid,
      required this.chapterIndex,
      required this.title,
      required final List<String> paragraphs})
      : _paragraphs = paragraphs;

  @override
  final int? id;
  @override
  final String bookUuid;
  @override
  final int chapterIndex;
  @override
  final String title;
  final List<String> _paragraphs;
  @override
  List<String> get paragraphs {
    if (_paragraphs is EqualUnmodifiableListView) return _paragraphs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_paragraphs);
  }

  @override
  String toString() {
    return 'Chapter(id: $id, bookUuid: $bookUuid, chapterIndex: $chapterIndex, title: $title, paragraphs: $paragraphs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChapterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookUuid, bookUuid) ||
                other.bookUuid == bookUuid) &&
            (identical(other.chapterIndex, chapterIndex) ||
                other.chapterIndex == chapterIndex) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._paragraphs, _paragraphs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, bookUuid, chapterIndex,
      title, const DeepCollectionEquality().hash(_paragraphs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChapterImplCopyWith<_$ChapterImpl> get copyWith =>
      __$$ChapterImplCopyWithImpl<_$ChapterImpl>(this, _$identity);
}

abstract class _Chapter implements Chapter {
  const factory _Chapter(
      {final int? id,
      required final String bookUuid,
      required final int chapterIndex,
      required final String title,
      required final List<String> paragraphs}) = _$ChapterImpl;

  @override
  int? get id;
  @override
  String get bookUuid;
  @override
  int get chapterIndex;
  @override
  String get title;
  @override
  List<String> get paragraphs;
  @override
  @JsonKey(ignore: true)
  _$$ChapterImplCopyWith<_$ChapterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

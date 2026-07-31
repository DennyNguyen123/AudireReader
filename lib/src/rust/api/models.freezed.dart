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
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppSettings {
  int get id => throw _privateConstructorUsedError;
  double get fontSize => throw _privateConstructorUsedError;
  double get speechRate => throw _privateConstructorUsedError;
  String? get selectedVoiceName => throw _privateConstructorUsedError;
  String? get selectedVoiceLocale => throw _privateConstructorUsedError;
  String get ttsProvider => throw _privateConstructorUsedError;
  String get openAiTtsEndpoint => throw _privateConstructorUsedError;
  String get openAiTtsApiKey => throw _privateConstructorUsedError;
  String get openAiTtsModel => throw _privateConstructorUsedError;
  int get ttsDownloadConcurrency => throw _privateConstructorUsedError;
  String get fontFamily => throw _privateConstructorUsedError;
  String get themeMode => throw _privateConstructorUsedError;
  String get appLocale => throw _privateConstructorUsedError;
  double get lineHeight => throw _privateConstructorUsedError;
  double get paragraphSpacing => throw _privateConstructorUsedError;
  String get textAlignment => throw _privateConstructorUsedError;
  double get sideMargin => throw _privateConstructorUsedError;
  String? get customBackgroundColor => throw _privateConstructorUsedError;
  String? get customTextColor => throw _privateConstructorUsedError;
  String? get primaryColorHex => throw _privateConstructorUsedError;
  bool get webDavEnabled => throw _privateConstructorUsedError;
  String get webDavUrl => throw _privateConstructorUsedError;
  String get webDavUsername => throw _privateConstructorUsedError;
  int? get webDavLastSync => throw _privateConstructorUsedError;
  String? get deviceId => throw _privateConstructorUsedError;
  String? get deviceName => throw _privateConstructorUsedError;
  bool get openLastReadOnLaunch => throw _privateConstructorUsedError;
  String get hotkeyNextParagraph => throw _privateConstructorUsedError;
  String get hotkeyPrevParagraph => throw _privateConstructorUsedError;
  String get hotkeyNextChapter => throw _privateConstructorUsedError;
  String get hotkeyPrevChapter => throw _privateConstructorUsedError;
  String get hotkeyPlayPauseTts => throw _privateConstructorUsedError;
  String get hotkeyOpenChapter => throw _privateConstructorUsedError;
  String get hotkeyOpenSetting => throw _privateConstructorUsedError;
  String get hotkeyBossKey => throw _privateConstructorUsedError;
  String get bossKeyAction => throw _privateConstructorUsedError;
  bool get autoCheckUpdate => throw _privateConstructorUsedError;
  bool get bgmEnabled => throw _privateConstructorUsedError;
  double get bgmVolume => throw _privateConstructorUsedError;
  int? get currentBgmTrackId => throw _privateConstructorUsedError;
  String? get currentBgmTrackUrl => throw _privateConstructorUsedError;
  String? get currentBgmTrackName => throw _privateConstructorUsedError;
  String get bgmLoopMode => throw _privateConstructorUsedError;
  String get bgmProviderId => throw _privateConstructorUsedError;
  String? get lastLocalTrackUrl => throw _privateConstructorUsedError;
  String? get lastRadioTrackUrl => throw _privateConstructorUsedError;
  String? get lastRadioTrackName => throw _privateConstructorUsedError;
  String? get lastLofiTrackUrl => throw _privateConstructorUsedError;
  String? get lastLofiTrackName => throw _privateConstructorUsedError;
  String get sortBy => throw _privateConstructorUsedError;
  bool get showAssistiveButton => throw _privateConstructorUsedError;
  double get assistiveButtonX => throw _privateConstructorUsedError;
  double get assistiveButtonY => throw _privateConstructorUsedError;
  String get assistiveSingleTapAction => throw _privateConstructorUsedError;
  String get assistiveDoubleTapAction => throw _privateConstructorUsedError;
  String get assistiveLongPressAction => throw _privateConstructorUsedError;
  bool get developerMode => throw _privateConstructorUsedError;
  bool get enableDebugLogs => throw _privateConstructorUsedError;
  bool get enableWebDavDebug => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppSettingsCopyWith<AppSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSettingsCopyWith<$Res> {
  factory $AppSettingsCopyWith(
    AppSettings value,
    $Res Function(AppSettings) then,
  ) = _$AppSettingsCopyWithImpl<$Res, AppSettings>;
  @useResult
  $Res call({
    int id,
    double fontSize,
    double speechRate,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
    String ttsProvider,
    String openAiTtsEndpoint,
    String openAiTtsApiKey,
    String openAiTtsModel,
    int ttsDownloadConcurrency,
    String fontFamily,
    String themeMode,
    String appLocale,
    double lineHeight,
    double paragraphSpacing,
    String textAlignment,
    double sideMargin,
    String? customBackgroundColor,
    String? customTextColor,
    String? primaryColorHex,
    bool webDavEnabled,
    String webDavUrl,
    String webDavUsername,
    int? webDavLastSync,
    String? deviceId,
    String? deviceName,
    bool openLastReadOnLaunch,
    String hotkeyNextParagraph,
    String hotkeyPrevParagraph,
    String hotkeyNextChapter,
    String hotkeyPrevChapter,
    String hotkeyPlayPauseTts,
    String hotkeyOpenChapter,
    String hotkeyOpenSetting,
    String hotkeyBossKey,
    String bossKeyAction,
    bool autoCheckUpdate,
    bool bgmEnabled,
    double bgmVolume,
    int? currentBgmTrackId,
    String? currentBgmTrackUrl,
    String? currentBgmTrackName,
    String bgmLoopMode,
    String bgmProviderId,
    String? lastLocalTrackUrl,
    String? lastRadioTrackUrl,
    String? lastRadioTrackName,
    String? lastLofiTrackUrl,
    String? lastLofiTrackName,
    String sortBy,
    bool showAssistiveButton,
    double assistiveButtonX,
    double assistiveButtonY,
    String assistiveSingleTapAction,
    String assistiveDoubleTapAction,
    String assistiveLongPressAction,
    bool developerMode,
    bool enableDebugLogs,
    bool enableWebDavDebug,
  });
}

/// @nodoc
class _$AppSettingsCopyWithImpl<$Res, $Val extends AppSettings>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fontSize = null,
    Object? speechRate = null,
    Object? selectedVoiceName = freezed,
    Object? selectedVoiceLocale = freezed,
    Object? ttsProvider = null,
    Object? openAiTtsEndpoint = null,
    Object? openAiTtsApiKey = null,
    Object? openAiTtsModel = null,
    Object? ttsDownloadConcurrency = null,
    Object? fontFamily = null,
    Object? themeMode = null,
    Object? appLocale = null,
    Object? lineHeight = null,
    Object? paragraphSpacing = null,
    Object? textAlignment = null,
    Object? sideMargin = null,
    Object? customBackgroundColor = freezed,
    Object? customTextColor = freezed,
    Object? primaryColorHex = freezed,
    Object? webDavEnabled = null,
    Object? webDavUrl = null,
    Object? webDavUsername = null,
    Object? webDavLastSync = freezed,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? openLastReadOnLaunch = null,
    Object? hotkeyNextParagraph = null,
    Object? hotkeyPrevParagraph = null,
    Object? hotkeyNextChapter = null,
    Object? hotkeyPrevChapter = null,
    Object? hotkeyPlayPauseTts = null,
    Object? hotkeyOpenChapter = null,
    Object? hotkeyOpenSetting = null,
    Object? hotkeyBossKey = null,
    Object? bossKeyAction = null,
    Object? autoCheckUpdate = null,
    Object? bgmEnabled = null,
    Object? bgmVolume = null,
    Object? currentBgmTrackId = freezed,
    Object? currentBgmTrackUrl = freezed,
    Object? currentBgmTrackName = freezed,
    Object? bgmLoopMode = null,
    Object? bgmProviderId = null,
    Object? lastLocalTrackUrl = freezed,
    Object? lastRadioTrackUrl = freezed,
    Object? lastRadioTrackName = freezed,
    Object? lastLofiTrackUrl = freezed,
    Object? lastLofiTrackName = freezed,
    Object? sortBy = null,
    Object? showAssistiveButton = null,
    Object? assistiveButtonX = null,
    Object? assistiveButtonY = null,
    Object? assistiveSingleTapAction = null,
    Object? assistiveDoubleTapAction = null,
    Object? assistiveLongPressAction = null,
    Object? developerMode = null,
    Object? enableDebugLogs = null,
    Object? enableWebDavDebug = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            fontSize: null == fontSize
                ? _value.fontSize
                : fontSize // ignore: cast_nullable_to_non_nullable
                      as double,
            speechRate: null == speechRate
                ? _value.speechRate
                : speechRate // ignore: cast_nullable_to_non_nullable
                      as double,
            selectedVoiceName: freezed == selectedVoiceName
                ? _value.selectedVoiceName
                : selectedVoiceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            selectedVoiceLocale: freezed == selectedVoiceLocale
                ? _value.selectedVoiceLocale
                : selectedVoiceLocale // ignore: cast_nullable_to_non_nullable
                      as String?,
            ttsProvider: null == ttsProvider
                ? _value.ttsProvider
                : ttsProvider // ignore: cast_nullable_to_non_nullable
                      as String,
            openAiTtsEndpoint: null == openAiTtsEndpoint
                ? _value.openAiTtsEndpoint
                : openAiTtsEndpoint // ignore: cast_nullable_to_non_nullable
                      as String,
            openAiTtsApiKey: null == openAiTtsApiKey
                ? _value.openAiTtsApiKey
                : openAiTtsApiKey // ignore: cast_nullable_to_non_nullable
                      as String,
            openAiTtsModel: null == openAiTtsModel
                ? _value.openAiTtsModel
                : openAiTtsModel // ignore: cast_nullable_to_non_nullable
                      as String,
            ttsDownloadConcurrency: null == ttsDownloadConcurrency
                ? _value.ttsDownloadConcurrency
                : ttsDownloadConcurrency // ignore: cast_nullable_to_non_nullable
                      as int,
            fontFamily: null == fontFamily
                ? _value.fontFamily
                : fontFamily // ignore: cast_nullable_to_non_nullable
                      as String,
            themeMode: null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
                      as String,
            appLocale: null == appLocale
                ? _value.appLocale
                : appLocale // ignore: cast_nullable_to_non_nullable
                      as String,
            lineHeight: null == lineHeight
                ? _value.lineHeight
                : lineHeight // ignore: cast_nullable_to_non_nullable
                      as double,
            paragraphSpacing: null == paragraphSpacing
                ? _value.paragraphSpacing
                : paragraphSpacing // ignore: cast_nullable_to_non_nullable
                      as double,
            textAlignment: null == textAlignment
                ? _value.textAlignment
                : textAlignment // ignore: cast_nullable_to_non_nullable
                      as String,
            sideMargin: null == sideMargin
                ? _value.sideMargin
                : sideMargin // ignore: cast_nullable_to_non_nullable
                      as double,
            customBackgroundColor: freezed == customBackgroundColor
                ? _value.customBackgroundColor
                : customBackgroundColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            customTextColor: freezed == customTextColor
                ? _value.customTextColor
                : customTextColor // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryColorHex: freezed == primaryColorHex
                ? _value.primaryColorHex
                : primaryColorHex // ignore: cast_nullable_to_non_nullable
                      as String?,
            webDavEnabled: null == webDavEnabled
                ? _value.webDavEnabled
                : webDavEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            webDavUrl: null == webDavUrl
                ? _value.webDavUrl
                : webDavUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            webDavUsername: null == webDavUsername
                ? _value.webDavUsername
                : webDavUsername // ignore: cast_nullable_to_non_nullable
                      as String,
            webDavLastSync: freezed == webDavLastSync
                ? _value.webDavLastSync
                : webDavLastSync // ignore: cast_nullable_to_non_nullable
                      as int?,
            deviceId: freezed == deviceId
                ? _value.deviceId
                : deviceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deviceName: freezed == deviceName
                ? _value.deviceName
                : deviceName // ignore: cast_nullable_to_non_nullable
                      as String?,
            openLastReadOnLaunch: null == openLastReadOnLaunch
                ? _value.openLastReadOnLaunch
                : openLastReadOnLaunch // ignore: cast_nullable_to_non_nullable
                      as bool,
            hotkeyNextParagraph: null == hotkeyNextParagraph
                ? _value.hotkeyNextParagraph
                : hotkeyNextParagraph // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyPrevParagraph: null == hotkeyPrevParagraph
                ? _value.hotkeyPrevParagraph
                : hotkeyPrevParagraph // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyNextChapter: null == hotkeyNextChapter
                ? _value.hotkeyNextChapter
                : hotkeyNextChapter // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyPrevChapter: null == hotkeyPrevChapter
                ? _value.hotkeyPrevChapter
                : hotkeyPrevChapter // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyPlayPauseTts: null == hotkeyPlayPauseTts
                ? _value.hotkeyPlayPauseTts
                : hotkeyPlayPauseTts // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyOpenChapter: null == hotkeyOpenChapter
                ? _value.hotkeyOpenChapter
                : hotkeyOpenChapter // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyOpenSetting: null == hotkeyOpenSetting
                ? _value.hotkeyOpenSetting
                : hotkeyOpenSetting // ignore: cast_nullable_to_non_nullable
                      as String,
            hotkeyBossKey: null == hotkeyBossKey
                ? _value.hotkeyBossKey
                : hotkeyBossKey // ignore: cast_nullable_to_non_nullable
                      as String,
            bossKeyAction: null == bossKeyAction
                ? _value.bossKeyAction
                : bossKeyAction // ignore: cast_nullable_to_non_nullable
                      as String,
            autoCheckUpdate: null == autoCheckUpdate
                ? _value.autoCheckUpdate
                : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
                      as bool,
            bgmEnabled: null == bgmEnabled
                ? _value.bgmEnabled
                : bgmEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            bgmVolume: null == bgmVolume
                ? _value.bgmVolume
                : bgmVolume // ignore: cast_nullable_to_non_nullable
                      as double,
            currentBgmTrackId: freezed == currentBgmTrackId
                ? _value.currentBgmTrackId
                : currentBgmTrackId // ignore: cast_nullable_to_non_nullable
                      as int?,
            currentBgmTrackUrl: freezed == currentBgmTrackUrl
                ? _value.currentBgmTrackUrl
                : currentBgmTrackUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentBgmTrackName: freezed == currentBgmTrackName
                ? _value.currentBgmTrackName
                : currentBgmTrackName // ignore: cast_nullable_to_non_nullable
                      as String?,
            bgmLoopMode: null == bgmLoopMode
                ? _value.bgmLoopMode
                : bgmLoopMode // ignore: cast_nullable_to_non_nullable
                      as String,
            bgmProviderId: null == bgmProviderId
                ? _value.bgmProviderId
                : bgmProviderId // ignore: cast_nullable_to_non_nullable
                      as String,
            lastLocalTrackUrl: freezed == lastLocalTrackUrl
                ? _value.lastLocalTrackUrl
                : lastLocalTrackUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastRadioTrackUrl: freezed == lastRadioTrackUrl
                ? _value.lastRadioTrackUrl
                : lastRadioTrackUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastRadioTrackName: freezed == lastRadioTrackName
                ? _value.lastRadioTrackName
                : lastRadioTrackName // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastLofiTrackUrl: freezed == lastLofiTrackUrl
                ? _value.lastLofiTrackUrl
                : lastLofiTrackUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastLofiTrackName: freezed == lastLofiTrackName
                ? _value.lastLofiTrackName
                : lastLofiTrackName // ignore: cast_nullable_to_non_nullable
                      as String?,
            sortBy: null == sortBy
                ? _value.sortBy
                : sortBy // ignore: cast_nullable_to_non_nullable
                      as String,
            showAssistiveButton: null == showAssistiveButton
                ? _value.showAssistiveButton
                : showAssistiveButton // ignore: cast_nullable_to_non_nullable
                      as bool,
            assistiveButtonX: null == assistiveButtonX
                ? _value.assistiveButtonX
                : assistiveButtonX // ignore: cast_nullable_to_non_nullable
                      as double,
            assistiveButtonY: null == assistiveButtonY
                ? _value.assistiveButtonY
                : assistiveButtonY // ignore: cast_nullable_to_non_nullable
                      as double,
            assistiveSingleTapAction: null == assistiveSingleTapAction
                ? _value.assistiveSingleTapAction
                : assistiveSingleTapAction // ignore: cast_nullable_to_non_nullable
                      as String,
            assistiveDoubleTapAction: null == assistiveDoubleTapAction
                ? _value.assistiveDoubleTapAction
                : assistiveDoubleTapAction // ignore: cast_nullable_to_non_nullable
                      as String,
            assistiveLongPressAction: null == assistiveLongPressAction
                ? _value.assistiveLongPressAction
                : assistiveLongPressAction // ignore: cast_nullable_to_non_nullable
                      as String,
            developerMode: null == developerMode
                ? _value.developerMode
                : developerMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            enableDebugLogs: null == enableDebugLogs
                ? _value.enableDebugLogs
                : enableDebugLogs // ignore: cast_nullable_to_non_nullable
                      as bool,
            enableWebDavDebug: null == enableWebDavDebug
                ? _value.enableWebDavDebug
                : enableWebDavDebug // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSettingsImplCopyWith<$Res>
    implements $AppSettingsCopyWith<$Res> {
  factory _$$AppSettingsImplCopyWith(
    _$AppSettingsImpl value,
    $Res Function(_$AppSettingsImpl) then,
  ) = __$$AppSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    double fontSize,
    double speechRate,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
    String ttsProvider,
    String openAiTtsEndpoint,
    String openAiTtsApiKey,
    String openAiTtsModel,
    int ttsDownloadConcurrency,
    String fontFamily,
    String themeMode,
    String appLocale,
    double lineHeight,
    double paragraphSpacing,
    String textAlignment,
    double sideMargin,
    String? customBackgroundColor,
    String? customTextColor,
    String? primaryColorHex,
    bool webDavEnabled,
    String webDavUrl,
    String webDavUsername,
    int? webDavLastSync,
    String? deviceId,
    String? deviceName,
    bool openLastReadOnLaunch,
    String hotkeyNextParagraph,
    String hotkeyPrevParagraph,
    String hotkeyNextChapter,
    String hotkeyPrevChapter,
    String hotkeyPlayPauseTts,
    String hotkeyOpenChapter,
    String hotkeyOpenSetting,
    String hotkeyBossKey,
    String bossKeyAction,
    bool autoCheckUpdate,
    bool bgmEnabled,
    double bgmVolume,
    int? currentBgmTrackId,
    String? currentBgmTrackUrl,
    String? currentBgmTrackName,
    String bgmLoopMode,
    String bgmProviderId,
    String? lastLocalTrackUrl,
    String? lastRadioTrackUrl,
    String? lastRadioTrackName,
    String? lastLofiTrackUrl,
    String? lastLofiTrackName,
    String sortBy,
    bool showAssistiveButton,
    double assistiveButtonX,
    double assistiveButtonY,
    String assistiveSingleTapAction,
    String assistiveDoubleTapAction,
    String assistiveLongPressAction,
    bool developerMode,
    bool enableDebugLogs,
    bool enableWebDavDebug,
  });
}

/// @nodoc
class __$$AppSettingsImplCopyWithImpl<$Res>
    extends _$AppSettingsCopyWithImpl<$Res, _$AppSettingsImpl>
    implements _$$AppSettingsImplCopyWith<$Res> {
  __$$AppSettingsImplCopyWithImpl(
    _$AppSettingsImpl _value,
    $Res Function(_$AppSettingsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fontSize = null,
    Object? speechRate = null,
    Object? selectedVoiceName = freezed,
    Object? selectedVoiceLocale = freezed,
    Object? ttsProvider = null,
    Object? openAiTtsEndpoint = null,
    Object? openAiTtsApiKey = null,
    Object? openAiTtsModel = null,
    Object? ttsDownloadConcurrency = null,
    Object? fontFamily = null,
    Object? themeMode = null,
    Object? appLocale = null,
    Object? lineHeight = null,
    Object? paragraphSpacing = null,
    Object? textAlignment = null,
    Object? sideMargin = null,
    Object? customBackgroundColor = freezed,
    Object? customTextColor = freezed,
    Object? primaryColorHex = freezed,
    Object? webDavEnabled = null,
    Object? webDavUrl = null,
    Object? webDavUsername = null,
    Object? webDavLastSync = freezed,
    Object? deviceId = freezed,
    Object? deviceName = freezed,
    Object? openLastReadOnLaunch = null,
    Object? hotkeyNextParagraph = null,
    Object? hotkeyPrevParagraph = null,
    Object? hotkeyNextChapter = null,
    Object? hotkeyPrevChapter = null,
    Object? hotkeyPlayPauseTts = null,
    Object? hotkeyOpenChapter = null,
    Object? hotkeyOpenSetting = null,
    Object? hotkeyBossKey = null,
    Object? bossKeyAction = null,
    Object? autoCheckUpdate = null,
    Object? bgmEnabled = null,
    Object? bgmVolume = null,
    Object? currentBgmTrackId = freezed,
    Object? currentBgmTrackUrl = freezed,
    Object? currentBgmTrackName = freezed,
    Object? bgmLoopMode = null,
    Object? bgmProviderId = null,
    Object? lastLocalTrackUrl = freezed,
    Object? lastRadioTrackUrl = freezed,
    Object? lastRadioTrackName = freezed,
    Object? lastLofiTrackUrl = freezed,
    Object? lastLofiTrackName = freezed,
    Object? sortBy = null,
    Object? showAssistiveButton = null,
    Object? assistiveButtonX = null,
    Object? assistiveButtonY = null,
    Object? assistiveSingleTapAction = null,
    Object? assistiveDoubleTapAction = null,
    Object? assistiveLongPressAction = null,
    Object? developerMode = null,
    Object? enableDebugLogs = null,
    Object? enableWebDavDebug = null,
  }) {
    return _then(
      _$AppSettingsImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        fontSize: null == fontSize
            ? _value.fontSize
            : fontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        speechRate: null == speechRate
            ? _value.speechRate
            : speechRate // ignore: cast_nullable_to_non_nullable
                  as double,
        selectedVoiceName: freezed == selectedVoiceName
            ? _value.selectedVoiceName
            : selectedVoiceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        selectedVoiceLocale: freezed == selectedVoiceLocale
            ? _value.selectedVoiceLocale
            : selectedVoiceLocale // ignore: cast_nullable_to_non_nullable
                  as String?,
        ttsProvider: null == ttsProvider
            ? _value.ttsProvider
            : ttsProvider // ignore: cast_nullable_to_non_nullable
                  as String,
        openAiTtsEndpoint: null == openAiTtsEndpoint
            ? _value.openAiTtsEndpoint
            : openAiTtsEndpoint // ignore: cast_nullable_to_non_nullable
                  as String,
        openAiTtsApiKey: null == openAiTtsApiKey
            ? _value.openAiTtsApiKey
            : openAiTtsApiKey // ignore: cast_nullable_to_non_nullable
                  as String,
        openAiTtsModel: null == openAiTtsModel
            ? _value.openAiTtsModel
            : openAiTtsModel // ignore: cast_nullable_to_non_nullable
                  as String,
        ttsDownloadConcurrency: null == ttsDownloadConcurrency
            ? _value.ttsDownloadConcurrency
            : ttsDownloadConcurrency // ignore: cast_nullable_to_non_nullable
                  as int,
        fontFamily: null == fontFamily
            ? _value.fontFamily
            : fontFamily // ignore: cast_nullable_to_non_nullable
                  as String,
        themeMode: null == themeMode
            ? _value.themeMode
            : themeMode // ignore: cast_nullable_to_non_nullable
                  as String,
        appLocale: null == appLocale
            ? _value.appLocale
            : appLocale // ignore: cast_nullable_to_non_nullable
                  as String,
        lineHeight: null == lineHeight
            ? _value.lineHeight
            : lineHeight // ignore: cast_nullable_to_non_nullable
                  as double,
        paragraphSpacing: null == paragraphSpacing
            ? _value.paragraphSpacing
            : paragraphSpacing // ignore: cast_nullable_to_non_nullable
                  as double,
        textAlignment: null == textAlignment
            ? _value.textAlignment
            : textAlignment // ignore: cast_nullable_to_non_nullable
                  as String,
        sideMargin: null == sideMargin
            ? _value.sideMargin
            : sideMargin // ignore: cast_nullable_to_non_nullable
                  as double,
        customBackgroundColor: freezed == customBackgroundColor
            ? _value.customBackgroundColor
            : customBackgroundColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        customTextColor: freezed == customTextColor
            ? _value.customTextColor
            : customTextColor // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryColorHex: freezed == primaryColorHex
            ? _value.primaryColorHex
            : primaryColorHex // ignore: cast_nullable_to_non_nullable
                  as String?,
        webDavEnabled: null == webDavEnabled
            ? _value.webDavEnabled
            : webDavEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        webDavUrl: null == webDavUrl
            ? _value.webDavUrl
            : webDavUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        webDavUsername: null == webDavUsername
            ? _value.webDavUsername
            : webDavUsername // ignore: cast_nullable_to_non_nullable
                  as String,
        webDavLastSync: freezed == webDavLastSync
            ? _value.webDavLastSync
            : webDavLastSync // ignore: cast_nullable_to_non_nullable
                  as int?,
        deviceId: freezed == deviceId
            ? _value.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deviceName: freezed == deviceName
            ? _value.deviceName
            : deviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        openLastReadOnLaunch: null == openLastReadOnLaunch
            ? _value.openLastReadOnLaunch
            : openLastReadOnLaunch // ignore: cast_nullable_to_non_nullable
                  as bool,
        hotkeyNextParagraph: null == hotkeyNextParagraph
            ? _value.hotkeyNextParagraph
            : hotkeyNextParagraph // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyPrevParagraph: null == hotkeyPrevParagraph
            ? _value.hotkeyPrevParagraph
            : hotkeyPrevParagraph // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyNextChapter: null == hotkeyNextChapter
            ? _value.hotkeyNextChapter
            : hotkeyNextChapter // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyPrevChapter: null == hotkeyPrevChapter
            ? _value.hotkeyPrevChapter
            : hotkeyPrevChapter // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyPlayPauseTts: null == hotkeyPlayPauseTts
            ? _value.hotkeyPlayPauseTts
            : hotkeyPlayPauseTts // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyOpenChapter: null == hotkeyOpenChapter
            ? _value.hotkeyOpenChapter
            : hotkeyOpenChapter // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyOpenSetting: null == hotkeyOpenSetting
            ? _value.hotkeyOpenSetting
            : hotkeyOpenSetting // ignore: cast_nullable_to_non_nullable
                  as String,
        hotkeyBossKey: null == hotkeyBossKey
            ? _value.hotkeyBossKey
            : hotkeyBossKey // ignore: cast_nullable_to_non_nullable
                  as String,
        bossKeyAction: null == bossKeyAction
            ? _value.bossKeyAction
            : bossKeyAction // ignore: cast_nullable_to_non_nullable
                  as String,
        autoCheckUpdate: null == autoCheckUpdate
            ? _value.autoCheckUpdate
            : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
                  as bool,
        bgmEnabled: null == bgmEnabled
            ? _value.bgmEnabled
            : bgmEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        bgmVolume: null == bgmVolume
            ? _value.bgmVolume
            : bgmVolume // ignore: cast_nullable_to_non_nullable
                  as double,
        currentBgmTrackId: freezed == currentBgmTrackId
            ? _value.currentBgmTrackId
            : currentBgmTrackId // ignore: cast_nullable_to_non_nullable
                  as int?,
        currentBgmTrackUrl: freezed == currentBgmTrackUrl
            ? _value.currentBgmTrackUrl
            : currentBgmTrackUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentBgmTrackName: freezed == currentBgmTrackName
            ? _value.currentBgmTrackName
            : currentBgmTrackName // ignore: cast_nullable_to_non_nullable
                  as String?,
        bgmLoopMode: null == bgmLoopMode
            ? _value.bgmLoopMode
            : bgmLoopMode // ignore: cast_nullable_to_non_nullable
                  as String,
        bgmProviderId: null == bgmProviderId
            ? _value.bgmProviderId
            : bgmProviderId // ignore: cast_nullable_to_non_nullable
                  as String,
        lastLocalTrackUrl: freezed == lastLocalTrackUrl
            ? _value.lastLocalTrackUrl
            : lastLocalTrackUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastRadioTrackUrl: freezed == lastRadioTrackUrl
            ? _value.lastRadioTrackUrl
            : lastRadioTrackUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastRadioTrackName: freezed == lastRadioTrackName
            ? _value.lastRadioTrackName
            : lastRadioTrackName // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastLofiTrackUrl: freezed == lastLofiTrackUrl
            ? _value.lastLofiTrackUrl
            : lastLofiTrackUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastLofiTrackName: freezed == lastLofiTrackName
            ? _value.lastLofiTrackName
            : lastLofiTrackName // ignore: cast_nullable_to_non_nullable
                  as String?,
        sortBy: null == sortBy
            ? _value.sortBy
            : sortBy // ignore: cast_nullable_to_non_nullable
                  as String,
        showAssistiveButton: null == showAssistiveButton
            ? _value.showAssistiveButton
            : showAssistiveButton // ignore: cast_nullable_to_non_nullable
                  as bool,
        assistiveButtonX: null == assistiveButtonX
            ? _value.assistiveButtonX
            : assistiveButtonX // ignore: cast_nullable_to_non_nullable
                  as double,
        assistiveButtonY: null == assistiveButtonY
            ? _value.assistiveButtonY
            : assistiveButtonY // ignore: cast_nullable_to_non_nullable
                  as double,
        assistiveSingleTapAction: null == assistiveSingleTapAction
            ? _value.assistiveSingleTapAction
            : assistiveSingleTapAction // ignore: cast_nullable_to_non_nullable
                  as String,
        assistiveDoubleTapAction: null == assistiveDoubleTapAction
            ? _value.assistiveDoubleTapAction
            : assistiveDoubleTapAction // ignore: cast_nullable_to_non_nullable
                  as String,
        assistiveLongPressAction: null == assistiveLongPressAction
            ? _value.assistiveLongPressAction
            : assistiveLongPressAction // ignore: cast_nullable_to_non_nullable
                  as String,
        developerMode: null == developerMode
            ? _value.developerMode
            : developerMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        enableDebugLogs: null == enableDebugLogs
            ? _value.enableDebugLogs
            : enableDebugLogs // ignore: cast_nullable_to_non_nullable
                  as bool,
        enableWebDavDebug: null == enableWebDavDebug
            ? _value.enableWebDavDebug
            : enableWebDavDebug // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$AppSettingsImpl implements _AppSettings {
  const _$AppSettingsImpl({
    required this.id,
    required this.fontSize,
    required this.speechRate,
    this.selectedVoiceName,
    this.selectedVoiceLocale,
    required this.ttsProvider,
    required this.openAiTtsEndpoint,
    required this.openAiTtsApiKey,
    required this.openAiTtsModel,
    required this.ttsDownloadConcurrency,
    required this.fontFamily,
    required this.themeMode,
    required this.appLocale,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.textAlignment,
    required this.sideMargin,
    this.customBackgroundColor,
    this.customTextColor,
    this.primaryColorHex,
    required this.webDavEnabled,
    required this.webDavUrl,
    required this.webDavUsername,
    this.webDavLastSync,
    this.deviceId,
    this.deviceName,
    required this.openLastReadOnLaunch,
    required this.hotkeyNextParagraph,
    required this.hotkeyPrevParagraph,
    required this.hotkeyNextChapter,
    required this.hotkeyPrevChapter,
    required this.hotkeyPlayPauseTts,
    required this.hotkeyOpenChapter,
    required this.hotkeyOpenSetting,
    required this.hotkeyBossKey,
    required this.bossKeyAction,
    required this.autoCheckUpdate,
    required this.bgmEnabled,
    required this.bgmVolume,
    this.currentBgmTrackId,
    this.currentBgmTrackUrl,
    this.currentBgmTrackName,
    required this.bgmLoopMode,
    required this.bgmProviderId,
    this.lastLocalTrackUrl,
    this.lastRadioTrackUrl,
    this.lastRadioTrackName,
    this.lastLofiTrackUrl,
    this.lastLofiTrackName,
    required this.sortBy,
    required this.showAssistiveButton,
    required this.assistiveButtonX,
    required this.assistiveButtonY,
    required this.assistiveSingleTapAction,
    required this.assistiveDoubleTapAction,
    required this.assistiveLongPressAction,
    required this.developerMode,
    required this.enableDebugLogs,
    required this.enableWebDavDebug,
  });

  @override
  final int id;
  @override
  final double fontSize;
  @override
  final double speechRate;
  @override
  final String? selectedVoiceName;
  @override
  final String? selectedVoiceLocale;
  @override
  final String ttsProvider;
  @override
  final String openAiTtsEndpoint;
  @override
  final String openAiTtsApiKey;
  @override
  final String openAiTtsModel;
  @override
  final int ttsDownloadConcurrency;
  @override
  final String fontFamily;
  @override
  final String themeMode;
  @override
  final String appLocale;
  @override
  final double lineHeight;
  @override
  final double paragraphSpacing;
  @override
  final String textAlignment;
  @override
  final double sideMargin;
  @override
  final String? customBackgroundColor;
  @override
  final String? customTextColor;
  @override
  final String? primaryColorHex;
  @override
  final bool webDavEnabled;
  @override
  final String webDavUrl;
  @override
  final String webDavUsername;
  @override
  final int? webDavLastSync;
  @override
  final String? deviceId;
  @override
  final String? deviceName;
  @override
  final bool openLastReadOnLaunch;
  @override
  final String hotkeyNextParagraph;
  @override
  final String hotkeyPrevParagraph;
  @override
  final String hotkeyNextChapter;
  @override
  final String hotkeyPrevChapter;
  @override
  final String hotkeyPlayPauseTts;
  @override
  final String hotkeyOpenChapter;
  @override
  final String hotkeyOpenSetting;
  @override
  final String hotkeyBossKey;
  @override
  final String bossKeyAction;
  @override
  final bool autoCheckUpdate;
  @override
  final bool bgmEnabled;
  @override
  final double bgmVolume;
  @override
  final int? currentBgmTrackId;
  @override
  final String? currentBgmTrackUrl;
  @override
  final String? currentBgmTrackName;
  @override
  final String bgmLoopMode;
  @override
  final String bgmProviderId;
  @override
  final String? lastLocalTrackUrl;
  @override
  final String? lastRadioTrackUrl;
  @override
  final String? lastRadioTrackName;
  @override
  final String? lastLofiTrackUrl;
  @override
  final String? lastLofiTrackName;
  @override
  final String sortBy;
  @override
  final bool showAssistiveButton;
  @override
  final double assistiveButtonX;
  @override
  final double assistiveButtonY;
  @override
  final String assistiveSingleTapAction;
  @override
  final String assistiveDoubleTapAction;
  @override
  final String assistiveLongPressAction;
  @override
  final bool developerMode;
  @override
  final bool enableDebugLogs;
  @override
  final bool enableWebDavDebug;

  @override
  String toString() {
    return 'AppSettings(id: $id, fontSize: $fontSize, speechRate: $speechRate, selectedVoiceName: $selectedVoiceName, selectedVoiceLocale: $selectedVoiceLocale, ttsProvider: $ttsProvider, openAiTtsEndpoint: $openAiTtsEndpoint, openAiTtsApiKey: $openAiTtsApiKey, openAiTtsModel: $openAiTtsModel, ttsDownloadConcurrency: $ttsDownloadConcurrency, fontFamily: $fontFamily, themeMode: $themeMode, appLocale: $appLocale, lineHeight: $lineHeight, paragraphSpacing: $paragraphSpacing, textAlignment: $textAlignment, sideMargin: $sideMargin, customBackgroundColor: $customBackgroundColor, customTextColor: $customTextColor, primaryColorHex: $primaryColorHex, webDavEnabled: $webDavEnabled, webDavUrl: $webDavUrl, webDavUsername: $webDavUsername, webDavLastSync: $webDavLastSync, deviceId: $deviceId, deviceName: $deviceName, openLastReadOnLaunch: $openLastReadOnLaunch, hotkeyNextParagraph: $hotkeyNextParagraph, hotkeyPrevParagraph: $hotkeyPrevParagraph, hotkeyNextChapter: $hotkeyNextChapter, hotkeyPrevChapter: $hotkeyPrevChapter, hotkeyPlayPauseTts: $hotkeyPlayPauseTts, hotkeyOpenChapter: $hotkeyOpenChapter, hotkeyOpenSetting: $hotkeyOpenSetting, hotkeyBossKey: $hotkeyBossKey, bossKeyAction: $bossKeyAction, autoCheckUpdate: $autoCheckUpdate, bgmEnabled: $bgmEnabled, bgmVolume: $bgmVolume, currentBgmTrackId: $currentBgmTrackId, currentBgmTrackUrl: $currentBgmTrackUrl, currentBgmTrackName: $currentBgmTrackName, bgmLoopMode: $bgmLoopMode, bgmProviderId: $bgmProviderId, lastLocalTrackUrl: $lastLocalTrackUrl, lastRadioTrackUrl: $lastRadioTrackUrl, lastRadioTrackName: $lastRadioTrackName, lastLofiTrackUrl: $lastLofiTrackUrl, lastLofiTrackName: $lastLofiTrackName, sortBy: $sortBy, showAssistiveButton: $showAssistiveButton, assistiveButtonX: $assistiveButtonX, assistiveButtonY: $assistiveButtonY, assistiveSingleTapAction: $assistiveSingleTapAction, assistiveDoubleTapAction: $assistiveDoubleTapAction, assistiveLongPressAction: $assistiveLongPressAction, developerMode: $developerMode, enableDebugLogs: $enableDebugLogs, enableWebDavDebug: $enableWebDavDebug)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSettingsImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.speechRate, speechRate) ||
                other.speechRate == speechRate) &&
            (identical(other.selectedVoiceName, selectedVoiceName) ||
                other.selectedVoiceName == selectedVoiceName) &&
            (identical(other.selectedVoiceLocale, selectedVoiceLocale) ||
                other.selectedVoiceLocale == selectedVoiceLocale) &&
            (identical(other.ttsProvider, ttsProvider) ||
                other.ttsProvider == ttsProvider) &&
            (identical(other.openAiTtsEndpoint, openAiTtsEndpoint) ||
                other.openAiTtsEndpoint == openAiTtsEndpoint) &&
            (identical(other.openAiTtsApiKey, openAiTtsApiKey) ||
                other.openAiTtsApiKey == openAiTtsApiKey) &&
            (identical(other.openAiTtsModel, openAiTtsModel) ||
                other.openAiTtsModel == openAiTtsModel) &&
            (identical(other.ttsDownloadConcurrency, ttsDownloadConcurrency) ||
                other.ttsDownloadConcurrency == ttsDownloadConcurrency) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.appLocale, appLocale) ||
                other.appLocale == appLocale) &&
            (identical(other.lineHeight, lineHeight) ||
                other.lineHeight == lineHeight) &&
            (identical(other.paragraphSpacing, paragraphSpacing) ||
                other.paragraphSpacing == paragraphSpacing) &&
            (identical(other.textAlignment, textAlignment) ||
                other.textAlignment == textAlignment) &&
            (identical(other.sideMargin, sideMargin) ||
                other.sideMargin == sideMargin) &&
            (identical(other.customBackgroundColor, customBackgroundColor) ||
                other.customBackgroundColor == customBackgroundColor) &&
            (identical(other.customTextColor, customTextColor) ||
                other.customTextColor == customTextColor) &&
            (identical(other.primaryColorHex, primaryColorHex) ||
                other.primaryColorHex == primaryColorHex) &&
            (identical(other.webDavEnabled, webDavEnabled) ||
                other.webDavEnabled == webDavEnabled) &&
            (identical(other.webDavUrl, webDavUrl) ||
                other.webDavUrl == webDavUrl) &&
            (identical(other.webDavUsername, webDavUsername) ||
                other.webDavUsername == webDavUsername) &&
            (identical(other.webDavLastSync, webDavLastSync) ||
                other.webDavLastSync == webDavLastSync) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.deviceName, deviceName) ||
                other.deviceName == deviceName) &&
            (identical(other.openLastReadOnLaunch, openLastReadOnLaunch) ||
                other.openLastReadOnLaunch == openLastReadOnLaunch) &&
            (identical(other.hotkeyNextParagraph, hotkeyNextParagraph) ||
                other.hotkeyNextParagraph == hotkeyNextParagraph) &&
            (identical(other.hotkeyPrevParagraph, hotkeyPrevParagraph) ||
                other.hotkeyPrevParagraph == hotkeyPrevParagraph) &&
            (identical(other.hotkeyNextChapter, hotkeyNextChapter) ||
                other.hotkeyNextChapter == hotkeyNextChapter) &&
            (identical(other.hotkeyPrevChapter, hotkeyPrevChapter) ||
                other.hotkeyPrevChapter == hotkeyPrevChapter) &&
            (identical(other.hotkeyPlayPauseTts, hotkeyPlayPauseTts) ||
                other.hotkeyPlayPauseTts == hotkeyPlayPauseTts) &&
            (identical(other.hotkeyOpenChapter, hotkeyOpenChapter) ||
                other.hotkeyOpenChapter == hotkeyOpenChapter) &&
            (identical(other.hotkeyOpenSetting, hotkeyOpenSetting) ||
                other.hotkeyOpenSetting == hotkeyOpenSetting) &&
            (identical(other.hotkeyBossKey, hotkeyBossKey) ||
                other.hotkeyBossKey == hotkeyBossKey) &&
            (identical(other.bossKeyAction, bossKeyAction) ||
                other.bossKeyAction == bossKeyAction) &&
            (identical(other.autoCheckUpdate, autoCheckUpdate) ||
                other.autoCheckUpdate == autoCheckUpdate) &&
            (identical(other.bgmEnabled, bgmEnabled) ||
                other.bgmEnabled == bgmEnabled) &&
            (identical(other.bgmVolume, bgmVolume) ||
                other.bgmVolume == bgmVolume) &&
            (identical(other.currentBgmTrackId, currentBgmTrackId) ||
                other.currentBgmTrackId == currentBgmTrackId) &&
            (identical(other.currentBgmTrackUrl, currentBgmTrackUrl) ||
                other.currentBgmTrackUrl == currentBgmTrackUrl) &&
            (identical(other.currentBgmTrackName, currentBgmTrackName) ||
                other.currentBgmTrackName == currentBgmTrackName) &&
            (identical(other.bgmLoopMode, bgmLoopMode) ||
                other.bgmLoopMode == bgmLoopMode) &&
            (identical(other.bgmProviderId, bgmProviderId) ||
                other.bgmProviderId == bgmProviderId) &&
            (identical(other.lastLocalTrackUrl, lastLocalTrackUrl) ||
                other.lastLocalTrackUrl == lastLocalTrackUrl) &&
            (identical(other.lastRadioTrackUrl, lastRadioTrackUrl) ||
                other.lastRadioTrackUrl == lastRadioTrackUrl) &&
            (identical(other.lastRadioTrackName, lastRadioTrackName) ||
                other.lastRadioTrackName == lastRadioTrackName) &&
            (identical(other.lastLofiTrackUrl, lastLofiTrackUrl) ||
                other.lastLofiTrackUrl == lastLofiTrackUrl) &&
            (identical(other.lastLofiTrackName, lastLofiTrackName) ||
                other.lastLofiTrackName == lastLofiTrackName) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.showAssistiveButton, showAssistiveButton) ||
                other.showAssistiveButton == showAssistiveButton) &&
            (identical(other.assistiveButtonX, assistiveButtonX) ||
                other.assistiveButtonX == assistiveButtonX) &&
            (identical(other.assistiveButtonY, assistiveButtonY) ||
                other.assistiveButtonY == assistiveButtonY) &&
            (identical(
                  other.assistiveSingleTapAction,
                  assistiveSingleTapAction,
                ) ||
                other.assistiveSingleTapAction == assistiveSingleTapAction) &&
            (identical(
                  other.assistiveDoubleTapAction,
                  assistiveDoubleTapAction,
                ) ||
                other.assistiveDoubleTapAction == assistiveDoubleTapAction) &&
            (identical(
                  other.assistiveLongPressAction,
                  assistiveLongPressAction,
                ) ||
                other.assistiveLongPressAction == assistiveLongPressAction) &&
            (identical(other.developerMode, developerMode) ||
                other.developerMode == developerMode) &&
            (identical(other.enableDebugLogs, enableDebugLogs) ||
                other.enableDebugLogs == enableDebugLogs) &&
            (identical(other.enableWebDavDebug, enableWebDavDebug) ||
                other.enableWebDavDebug == enableWebDavDebug));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    fontSize,
    speechRate,
    selectedVoiceName,
    selectedVoiceLocale,
    ttsProvider,
    openAiTtsEndpoint,
    openAiTtsApiKey,
    openAiTtsModel,
    ttsDownloadConcurrency,
    fontFamily,
    themeMode,
    appLocale,
    lineHeight,
    paragraphSpacing,
    textAlignment,
    sideMargin,
    customBackgroundColor,
    customTextColor,
    primaryColorHex,
    webDavEnabled,
    webDavUrl,
    webDavUsername,
    webDavLastSync,
    deviceId,
    deviceName,
    openLastReadOnLaunch,
    hotkeyNextParagraph,
    hotkeyPrevParagraph,
    hotkeyNextChapter,
    hotkeyPrevChapter,
    hotkeyPlayPauseTts,
    hotkeyOpenChapter,
    hotkeyOpenSetting,
    hotkeyBossKey,
    bossKeyAction,
    autoCheckUpdate,
    bgmEnabled,
    bgmVolume,
    currentBgmTrackId,
    currentBgmTrackUrl,
    currentBgmTrackName,
    bgmLoopMode,
    bgmProviderId,
    lastLocalTrackUrl,
    lastRadioTrackUrl,
    lastRadioTrackName,
    lastLofiTrackUrl,
    lastLofiTrackName,
    sortBy,
    showAssistiveButton,
    assistiveButtonX,
    assistiveButtonY,
    assistiveSingleTapAction,
    assistiveDoubleTapAction,
    assistiveLongPressAction,
    developerMode,
    enableDebugLogs,
    enableWebDavDebug,
  ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      __$$AppSettingsImplCopyWithImpl<_$AppSettingsImpl>(this, _$identity);
}

abstract class _AppSettings implements AppSettings {
  const factory _AppSettings({
    required final int id,
    required final double fontSize,
    required final double speechRate,
    final String? selectedVoiceName,
    final String? selectedVoiceLocale,
    required final String ttsProvider,
    required final String openAiTtsEndpoint,
    required final String openAiTtsApiKey,
    required final String openAiTtsModel,
    required final int ttsDownloadConcurrency,
    required final String fontFamily,
    required final String themeMode,
    required final String appLocale,
    required final double lineHeight,
    required final double paragraphSpacing,
    required final String textAlignment,
    required final double sideMargin,
    final String? customBackgroundColor,
    final String? customTextColor,
    final String? primaryColorHex,
    required final bool webDavEnabled,
    required final String webDavUrl,
    required final String webDavUsername,
    final int? webDavLastSync,
    final String? deviceId,
    final String? deviceName,
    required final bool openLastReadOnLaunch,
    required final String hotkeyNextParagraph,
    required final String hotkeyPrevParagraph,
    required final String hotkeyNextChapter,
    required final String hotkeyPrevChapter,
    required final String hotkeyPlayPauseTts,
    required final String hotkeyOpenChapter,
    required final String hotkeyOpenSetting,
    required final String hotkeyBossKey,
    required final String bossKeyAction,
    required final bool autoCheckUpdate,
    required final bool bgmEnabled,
    required final double bgmVolume,
    final int? currentBgmTrackId,
    final String? currentBgmTrackUrl,
    final String? currentBgmTrackName,
    required final String bgmLoopMode,
    required final String bgmProviderId,
    final String? lastLocalTrackUrl,
    final String? lastRadioTrackUrl,
    final String? lastRadioTrackName,
    final String? lastLofiTrackUrl,
    final String? lastLofiTrackName,
    required final String sortBy,
    required final bool showAssistiveButton,
    required final double assistiveButtonX,
    required final double assistiveButtonY,
    required final String assistiveSingleTapAction,
    required final String assistiveDoubleTapAction,
    required final String assistiveLongPressAction,
    required final bool developerMode,
    required final bool enableDebugLogs,
    required final bool enableWebDavDebug,
  }) = _$AppSettingsImpl;

  @override
  int get id;
  @override
  double get fontSize;
  @override
  double get speechRate;
  @override
  String? get selectedVoiceName;
  @override
  String? get selectedVoiceLocale;
  @override
  String get ttsProvider;
  @override
  String get openAiTtsEndpoint;
  @override
  String get openAiTtsApiKey;
  @override
  String get openAiTtsModel;
  @override
  int get ttsDownloadConcurrency;
  @override
  String get fontFamily;
  @override
  String get themeMode;
  @override
  String get appLocale;
  @override
  double get lineHeight;
  @override
  double get paragraphSpacing;
  @override
  String get textAlignment;
  @override
  double get sideMargin;
  @override
  String? get customBackgroundColor;
  @override
  String? get customTextColor;
  @override
  String? get primaryColorHex;
  @override
  bool get webDavEnabled;
  @override
  String get webDavUrl;
  @override
  String get webDavUsername;
  @override
  int? get webDavLastSync;
  @override
  String? get deviceId;
  @override
  String? get deviceName;
  @override
  bool get openLastReadOnLaunch;
  @override
  String get hotkeyNextParagraph;
  @override
  String get hotkeyPrevParagraph;
  @override
  String get hotkeyNextChapter;
  @override
  String get hotkeyPrevChapter;
  @override
  String get hotkeyPlayPauseTts;
  @override
  String get hotkeyOpenChapter;
  @override
  String get hotkeyOpenSetting;
  @override
  String get hotkeyBossKey;
  @override
  String get bossKeyAction;
  @override
  bool get autoCheckUpdate;
  @override
  bool get bgmEnabled;
  @override
  double get bgmVolume;
  @override
  int? get currentBgmTrackId;
  @override
  String? get currentBgmTrackUrl;
  @override
  String? get currentBgmTrackName;
  @override
  String get bgmLoopMode;
  @override
  String get bgmProviderId;
  @override
  String? get lastLocalTrackUrl;
  @override
  String? get lastRadioTrackUrl;
  @override
  String? get lastRadioTrackName;
  @override
  String? get lastLofiTrackUrl;
  @override
  String? get lastLofiTrackName;
  @override
  String get sortBy;
  @override
  bool get showAssistiveButton;
  @override
  double get assistiveButtonX;
  @override
  double get assistiveButtonY;
  @override
  String get assistiveSingleTapAction;
  @override
  String get assistiveDoubleTapAction;
  @override
  String get assistiveLongPressAction;
  @override
  bool get developerMode;
  @override
  bool get enableDebugLogs;
  @override
  bool get enableWebDavDebug;
  @override
  @JsonKey(ignore: true)
  _$$AppSettingsImplCopyWith<_$AppSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BgmTrack {
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get sourceType => throw _privateConstructorUsedError;
  String get sourcePath => throw _privateConstructorUsedError;
  int get dateAdded => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BgmTrackCopyWith<BgmTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BgmTrackCopyWith<$Res> {
  factory $BgmTrackCopyWith(BgmTrack value, $Res Function(BgmTrack) then) =
      _$BgmTrackCopyWithImpl<$Res, BgmTrack>;
  @useResult
  $Res call({
    int? id,
    String name,
    String sourceType,
    String sourcePath,
    int dateAdded,
  });
}

/// @nodoc
class _$BgmTrackCopyWithImpl<$Res, $Val extends BgmTrack>
    implements $BgmTrackCopyWith<$Res> {
  _$BgmTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? sourceType = null,
    Object? sourcePath = null,
    Object? dateAdded = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as String,
            sourcePath: null == sourcePath
                ? _value.sourcePath
                : sourcePath // ignore: cast_nullable_to_non_nullable
                      as String,
            dateAdded: null == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BgmTrackImplCopyWith<$Res>
    implements $BgmTrackCopyWith<$Res> {
  factory _$$BgmTrackImplCopyWith(
    _$BgmTrackImpl value,
    $Res Function(_$BgmTrackImpl) then,
  ) = __$$BgmTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String name,
    String sourceType,
    String sourcePath,
    int dateAdded,
  });
}

/// @nodoc
class __$$BgmTrackImplCopyWithImpl<$Res>
    extends _$BgmTrackCopyWithImpl<$Res, _$BgmTrackImpl>
    implements _$$BgmTrackImplCopyWith<$Res> {
  __$$BgmTrackImplCopyWithImpl(
    _$BgmTrackImpl _value,
    $Res Function(_$BgmTrackImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? sourceType = null,
    Object? sourcePath = null,
    Object? dateAdded = null,
  }) {
    return _then(
      _$BgmTrackImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as String,
        sourcePath: null == sourcePath
            ? _value.sourcePath
            : sourcePath // ignore: cast_nullable_to_non_nullable
                  as String,
        dateAdded: null == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BgmTrackImpl implements _BgmTrack {
  const _$BgmTrackImpl({
    this.id,
    required this.name,
    required this.sourceType,
    required this.sourcePath,
    required this.dateAdded,
  });

  @override
  final int? id;
  @override
  final String name;
  @override
  final String sourceType;
  @override
  final String sourcePath;
  @override
  final int dateAdded;

  @override
  String toString() {
    return 'BgmTrack(id: $id, name: $name, sourceType: $sourceType, sourcePath: $sourcePath, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BgmTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.sourcePath, sourcePath) ||
                other.sourcePath == sourcePath) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, sourceType, sourcePath, dateAdded);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BgmTrackImplCopyWith<_$BgmTrackImpl> get copyWith =>
      __$$BgmTrackImplCopyWithImpl<_$BgmTrackImpl>(this, _$identity);
}

abstract class _BgmTrack implements BgmTrack {
  const factory _BgmTrack({
    final int? id,
    required final String name,
    required final String sourceType,
    required final String sourcePath,
    required final int dateAdded,
  }) = _$BgmTrackImpl;

  @override
  int? get id;
  @override
  String get name;
  @override
  String get sourceType;
  @override
  String get sourcePath;
  @override
  int get dateAdded;
  @override
  @JsonKey(ignore: true)
  _$$BgmTrackImplCopyWith<_$BgmTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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
  $Res call({
    int? id,
    String uuid,
    String title,
    String author,
    String? coverPath,
    int totalChapters,
    int dateAdded,
    String status,
    List<String> tags,
  });
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
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookImplCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$$BookImplCopyWith(
    _$BookImpl value,
    $Res Function(_$BookImpl) then,
  ) = __$$BookImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String uuid,
    String title,
    String author,
    String? coverPath,
    int totalChapters,
    int dateAdded,
    String status,
    List<String> tags,
  });
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
    return _then(
      _$BookImpl(
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
      ),
    );
  }
}

/// @nodoc

class _$BookImpl implements _Book {
  const _$BookImpl({
    this.id,
    required this.uuid,
    required this.title,
    required this.author,
    this.coverPath,
    required this.totalChapters,
    required this.dateAdded,
    required this.status,
    required final List<String> tags,
  }) : _tags = tags;

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
    const DeepCollectionEquality().hash(_tags),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookImplCopyWith<_$BookImpl> get copyWith =>
      __$$BookImplCopyWithImpl<_$BookImpl>(this, _$identity);
}

abstract class _Book implements Book {
  const factory _Book({
    final int? id,
    required final String uuid,
    required final String title,
    required final String author,
    final String? coverPath,
    required final int totalChapters,
    required final int dateAdded,
    required final String status,
    required final List<String> tags,
  }) = _$BookImpl;

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
mixin _$Bookmark {
  int? get id => throw _privateConstructorUsedError;
  String get bookUuid => throw _privateConstructorUsedError;
  int get chapterIndex => throw _privateConstructorUsedError;
  int get paragraphIndex => throw _privateConstructorUsedError;
  String get contentSnippet => throw _privateConstructorUsedError;
  int get dateAdded => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BookmarkCopyWith<Bookmark> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookmarkCopyWith<$Res> {
  factory $BookmarkCopyWith(Bookmark value, $Res Function(Bookmark) then) =
      _$BookmarkCopyWithImpl<$Res, Bookmark>;
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
    String contentSnippet,
    int dateAdded,
  });
}

/// @nodoc
class _$BookmarkCopyWithImpl<$Res, $Val extends Bookmark>
    implements $BookmarkCopyWith<$Res> {
  _$BookmarkCopyWithImpl(this._value, this._then);

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
    Object? paragraphIndex = null,
    Object? contentSnippet = null,
    Object? dateAdded = null,
  }) {
    return _then(
      _value.copyWith(
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
            paragraphIndex: null == paragraphIndex
                ? _value.paragraphIndex
                : paragraphIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            contentSnippet: null == contentSnippet
                ? _value.contentSnippet
                : contentSnippet // ignore: cast_nullable_to_non_nullable
                      as String,
            dateAdded: null == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BookmarkImplCopyWith<$Res>
    implements $BookmarkCopyWith<$Res> {
  factory _$$BookmarkImplCopyWith(
    _$BookmarkImpl value,
    $Res Function(_$BookmarkImpl) then,
  ) = __$$BookmarkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
    String contentSnippet,
    int dateAdded,
  });
}

/// @nodoc
class __$$BookmarkImplCopyWithImpl<$Res>
    extends _$BookmarkCopyWithImpl<$Res, _$BookmarkImpl>
    implements _$$BookmarkImplCopyWith<$Res> {
  __$$BookmarkImplCopyWithImpl(
    _$BookmarkImpl _value,
    $Res Function(_$BookmarkImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? paragraphIndex = null,
    Object? contentSnippet = null,
    Object? dateAdded = null,
  }) {
    return _then(
      _$BookmarkImpl(
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
        paragraphIndex: null == paragraphIndex
            ? _value.paragraphIndex
            : paragraphIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        contentSnippet: null == contentSnippet
            ? _value.contentSnippet
            : contentSnippet // ignore: cast_nullable_to_non_nullable
                  as String,
        dateAdded: null == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$BookmarkImpl implements _Bookmark {
  const _$BookmarkImpl({
    this.id,
    required this.bookUuid,
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.contentSnippet,
    required this.dateAdded,
  });

  @override
  final int? id;
  @override
  final String bookUuid;
  @override
  final int chapterIndex;
  @override
  final int paragraphIndex;
  @override
  final String contentSnippet;
  @override
  final int dateAdded;

  @override
  String toString() {
    return 'Bookmark(id: $id, bookUuid: $bookUuid, chapterIndex: $chapterIndex, paragraphIndex: $paragraphIndex, contentSnippet: $contentSnippet, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookmarkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookUuid, bookUuid) ||
                other.bookUuid == bookUuid) &&
            (identical(other.chapterIndex, chapterIndex) ||
                other.chapterIndex == chapterIndex) &&
            (identical(other.paragraphIndex, paragraphIndex) ||
                other.paragraphIndex == paragraphIndex) &&
            (identical(other.contentSnippet, contentSnippet) ||
                other.contentSnippet == contentSnippet) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookUuid,
    chapterIndex,
    paragraphIndex,
    contentSnippet,
    dateAdded,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BookmarkImplCopyWith<_$BookmarkImpl> get copyWith =>
      __$$BookmarkImplCopyWithImpl<_$BookmarkImpl>(this, _$identity);
}

abstract class _Bookmark implements Bookmark {
  const factory _Bookmark({
    final int? id,
    required final String bookUuid,
    required final int chapterIndex,
    required final int paragraphIndex,
    required final String contentSnippet,
    required final int dateAdded,
  }) = _$BookmarkImpl;

  @override
  int? get id;
  @override
  String get bookUuid;
  @override
  int get chapterIndex;
  @override
  int get paragraphIndex;
  @override
  String get contentSnippet;
  @override
  int get dateAdded;
  @override
  @JsonKey(ignore: true)
  _$$BookmarkImplCopyWith<_$BookmarkImpl> get copyWith =>
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
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    String title,
    List<String> paragraphs,
  });
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
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChapterImplCopyWith<$Res> implements $ChapterCopyWith<$Res> {
  factory _$$ChapterImplCopyWith(
    _$ChapterImpl value,
    $Res Function(_$ChapterImpl) then,
  ) = __$$ChapterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    String title,
    List<String> paragraphs,
  });
}

/// @nodoc
class __$$ChapterImplCopyWithImpl<$Res>
    extends _$ChapterCopyWithImpl<$Res, _$ChapterImpl>
    implements _$$ChapterImplCopyWith<$Res> {
  __$$ChapterImplCopyWithImpl(
    _$ChapterImpl _value,
    $Res Function(_$ChapterImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? title = null,
    Object? paragraphs = null,
  }) {
    return _then(
      _$ChapterImpl(
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
      ),
    );
  }
}

/// @nodoc

class _$ChapterImpl implements _Chapter {
  const _$ChapterImpl({
    this.id,
    required this.bookUuid,
    required this.chapterIndex,
    required this.title,
    required final List<String> paragraphs,
  }) : _paragraphs = paragraphs;

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
            const DeepCollectionEquality().equals(
              other._paragraphs,
              _paragraphs,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookUuid,
    chapterIndex,
    title,
    const DeepCollectionEquality().hash(_paragraphs),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChapterImplCopyWith<_$ChapterImpl> get copyWith =>
      __$$ChapterImplCopyWithImpl<_$ChapterImpl>(this, _$identity);
}

abstract class _Chapter implements Chapter {
  const factory _Chapter({
    final int? id,
    required final String bookUuid,
    required final int chapterIndex,
    required final String title,
    required final List<String> paragraphs,
  }) = _$ChapterImpl;

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

/// @nodoc
mixin _$Highlight {
  int? get id => throw _privateConstructorUsedError;
  String get bookUuid => throw _privateConstructorUsedError;
  int get chapterIndex => throw _privateConstructorUsedError;
  int get paragraphIndex => throw _privateConstructorUsedError;
  int? get startOffset => throw _privateConstructorUsedError;
  int? get endOffset => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get colorHex => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get dateAdded => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $HighlightCopyWith<Highlight> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HighlightCopyWith<$Res> {
  factory $HighlightCopyWith(Highlight value, $Res Function(Highlight) then) =
      _$HighlightCopyWithImpl<$Res, Highlight>;
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
    int? startOffset,
    int? endOffset,
    String text,
    String colorHex,
    String? note,
    int dateAdded,
  });
}

/// @nodoc
class _$HighlightCopyWithImpl<$Res, $Val extends Highlight>
    implements $HighlightCopyWith<$Res> {
  _$HighlightCopyWithImpl(this._value, this._then);

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
    Object? paragraphIndex = null,
    Object? startOffset = freezed,
    Object? endOffset = freezed,
    Object? text = null,
    Object? colorHex = null,
    Object? note = freezed,
    Object? dateAdded = null,
  }) {
    return _then(
      _value.copyWith(
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
            paragraphIndex: null == paragraphIndex
                ? _value.paragraphIndex
                : paragraphIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            startOffset: freezed == startOffset
                ? _value.startOffset
                : startOffset // ignore: cast_nullable_to_non_nullable
                      as int?,
            endOffset: freezed == endOffset
                ? _value.endOffset
                : endOffset // ignore: cast_nullable_to_non_nullable
                      as int?,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            colorHex: null == colorHex
                ? _value.colorHex
                : colorHex // ignore: cast_nullable_to_non_nullable
                      as String,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateAdded: null == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HighlightImplCopyWith<$Res>
    implements $HighlightCopyWith<$Res> {
  factory _$$HighlightImplCopyWith(
    _$HighlightImpl value,
    $Res Function(_$HighlightImpl) then,
  ) = __$$HighlightImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    int paragraphIndex,
    int? startOffset,
    int? endOffset,
    String text,
    String colorHex,
    String? note,
    int dateAdded,
  });
}

/// @nodoc
class __$$HighlightImplCopyWithImpl<$Res>
    extends _$HighlightCopyWithImpl<$Res, _$HighlightImpl>
    implements _$$HighlightImplCopyWith<$Res> {
  __$$HighlightImplCopyWithImpl(
    _$HighlightImpl _value,
    $Res Function(_$HighlightImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? paragraphIndex = null,
    Object? startOffset = freezed,
    Object? endOffset = freezed,
    Object? text = null,
    Object? colorHex = null,
    Object? note = freezed,
    Object? dateAdded = null,
  }) {
    return _then(
      _$HighlightImpl(
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
        paragraphIndex: null == paragraphIndex
            ? _value.paragraphIndex
            : paragraphIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        startOffset: freezed == startOffset
            ? _value.startOffset
            : startOffset // ignore: cast_nullable_to_non_nullable
                  as int?,
        endOffset: freezed == endOffset
            ? _value.endOffset
            : endOffset // ignore: cast_nullable_to_non_nullable
                  as int?,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        colorHex: null == colorHex
            ? _value.colorHex
            : colorHex // ignore: cast_nullable_to_non_nullable
                  as String,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateAdded: null == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$HighlightImpl implements _Highlight {
  const _$HighlightImpl({
    this.id,
    required this.bookUuid,
    required this.chapterIndex,
    required this.paragraphIndex,
    this.startOffset,
    this.endOffset,
    required this.text,
    required this.colorHex,
    this.note,
    required this.dateAdded,
  });

  @override
  final int? id;
  @override
  final String bookUuid;
  @override
  final int chapterIndex;
  @override
  final int paragraphIndex;
  @override
  final int? startOffset;
  @override
  final int? endOffset;
  @override
  final String text;
  @override
  final String colorHex;
  @override
  final String? note;
  @override
  final int dateAdded;

  @override
  String toString() {
    return 'Highlight(id: $id, bookUuid: $bookUuid, chapterIndex: $chapterIndex, paragraphIndex: $paragraphIndex, startOffset: $startOffset, endOffset: $endOffset, text: $text, colorHex: $colorHex, note: $note, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HighlightImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookUuid, bookUuid) ||
                other.bookUuid == bookUuid) &&
            (identical(other.chapterIndex, chapterIndex) ||
                other.chapterIndex == chapterIndex) &&
            (identical(other.paragraphIndex, paragraphIndex) ||
                other.paragraphIndex == paragraphIndex) &&
            (identical(other.startOffset, startOffset) ||
                other.startOffset == startOffset) &&
            (identical(other.endOffset, endOffset) ||
                other.endOffset == endOffset) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookUuid,
    chapterIndex,
    paragraphIndex,
    startOffset,
    endOffset,
    text,
    colorHex,
    note,
    dateAdded,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HighlightImplCopyWith<_$HighlightImpl> get copyWith =>
      __$$HighlightImplCopyWithImpl<_$HighlightImpl>(this, _$identity);
}

abstract class _Highlight implements Highlight {
  const factory _Highlight({
    final int? id,
    required final String bookUuid,
    required final int chapterIndex,
    required final int paragraphIndex,
    final int? startOffset,
    final int? endOffset,
    required final String text,
    required final String colorHex,
    final String? note,
    required final int dateAdded,
  }) = _$HighlightImpl;

  @override
  int? get id;
  @override
  String get bookUuid;
  @override
  int get chapterIndex;
  @override
  int get paragraphIndex;
  @override
  int? get startOffset;
  @override
  int? get endOffset;
  @override
  String get text;
  @override
  String get colorHex;
  @override
  String? get note;
  @override
  int get dateAdded;
  @override
  @JsonKey(ignore: true)
  _$$HighlightImplCopyWith<_$HighlightImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$OfflineTtsRecord {
  int? get id => throw _privateConstructorUsedError;
  String get bookUuid => throw _privateConstructorUsedError;
  int get chapterIndex => throw _privateConstructorUsedError;
  String get ttsProvider => throw _privateConstructorUsedError;
  String get voiceName => throw _privateConstructorUsedError;
  double get speechRate => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  int get totalParagraphs => throw _privateConstructorUsedError;
  int get downloadedParagraphs => throw _privateConstructorUsedError;
  int get totalSizeBytes => throw _privateConstructorUsedError;
  int get downloadedAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OfflineTtsRecordCopyWith<OfflineTtsRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfflineTtsRecordCopyWith<$Res> {
  factory $OfflineTtsRecordCopyWith(
    OfflineTtsRecord value,
    $Res Function(OfflineTtsRecord) then,
  ) = _$OfflineTtsRecordCopyWithImpl<$Res, OfflineTtsRecord>;
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    String ttsProvider,
    String voiceName,
    double speechRate,
    bool isCompleted,
    int totalParagraphs,
    int downloadedParagraphs,
    int totalSizeBytes,
    int downloadedAt,
  });
}

/// @nodoc
class _$OfflineTtsRecordCopyWithImpl<$Res, $Val extends OfflineTtsRecord>
    implements $OfflineTtsRecordCopyWith<$Res> {
  _$OfflineTtsRecordCopyWithImpl(this._value, this._then);

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
    Object? ttsProvider = null,
    Object? voiceName = null,
    Object? speechRate = null,
    Object? isCompleted = null,
    Object? totalParagraphs = null,
    Object? downloadedParagraphs = null,
    Object? totalSizeBytes = null,
    Object? downloadedAt = null,
  }) {
    return _then(
      _value.copyWith(
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
            ttsProvider: null == ttsProvider
                ? _value.ttsProvider
                : ttsProvider // ignore: cast_nullable_to_non_nullable
                      as String,
            voiceName: null == voiceName
                ? _value.voiceName
                : voiceName // ignore: cast_nullable_to_non_nullable
                      as String,
            speechRate: null == speechRate
                ? _value.speechRate
                : speechRate // ignore: cast_nullable_to_non_nullable
                      as double,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalParagraphs: null == totalParagraphs
                ? _value.totalParagraphs
                : totalParagraphs // ignore: cast_nullable_to_non_nullable
                      as int,
            downloadedParagraphs: null == downloadedParagraphs
                ? _value.downloadedParagraphs
                : downloadedParagraphs // ignore: cast_nullable_to_non_nullable
                      as int,
            totalSizeBytes: null == totalSizeBytes
                ? _value.totalSizeBytes
                : totalSizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            downloadedAt: null == downloadedAt
                ? _value.downloadedAt
                : downloadedAt // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OfflineTtsRecordImplCopyWith<$Res>
    implements $OfflineTtsRecordCopyWith<$Res> {
  factory _$$OfflineTtsRecordImplCopyWith(
    _$OfflineTtsRecordImpl value,
    $Res Function(_$OfflineTtsRecordImpl) then,
  ) = __$$OfflineTtsRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int chapterIndex,
    String ttsProvider,
    String voiceName,
    double speechRate,
    bool isCompleted,
    int totalParagraphs,
    int downloadedParagraphs,
    int totalSizeBytes,
    int downloadedAt,
  });
}

/// @nodoc
class __$$OfflineTtsRecordImplCopyWithImpl<$Res>
    extends _$OfflineTtsRecordCopyWithImpl<$Res, _$OfflineTtsRecordImpl>
    implements _$$OfflineTtsRecordImplCopyWith<$Res> {
  __$$OfflineTtsRecordImplCopyWithImpl(
    _$OfflineTtsRecordImpl _value,
    $Res Function(_$OfflineTtsRecordImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? chapterIndex = null,
    Object? ttsProvider = null,
    Object? voiceName = null,
    Object? speechRate = null,
    Object? isCompleted = null,
    Object? totalParagraphs = null,
    Object? downloadedParagraphs = null,
    Object? totalSizeBytes = null,
    Object? downloadedAt = null,
  }) {
    return _then(
      _$OfflineTtsRecordImpl(
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
        ttsProvider: null == ttsProvider
            ? _value.ttsProvider
            : ttsProvider // ignore: cast_nullable_to_non_nullable
                  as String,
        voiceName: null == voiceName
            ? _value.voiceName
            : voiceName // ignore: cast_nullable_to_non_nullable
                  as String,
        speechRate: null == speechRate
            ? _value.speechRate
            : speechRate // ignore: cast_nullable_to_non_nullable
                  as double,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalParagraphs: null == totalParagraphs
            ? _value.totalParagraphs
            : totalParagraphs // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedParagraphs: null == downloadedParagraphs
            ? _value.downloadedParagraphs
            : downloadedParagraphs // ignore: cast_nullable_to_non_nullable
                  as int,
        totalSizeBytes: null == totalSizeBytes
            ? _value.totalSizeBytes
            : totalSizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        downloadedAt: null == downloadedAt
            ? _value.downloadedAt
            : downloadedAt // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$OfflineTtsRecordImpl implements _OfflineTtsRecord {
  const _$OfflineTtsRecordImpl({
    this.id,
    required this.bookUuid,
    required this.chapterIndex,
    required this.ttsProvider,
    required this.voiceName,
    required this.speechRate,
    required this.isCompleted,
    required this.totalParagraphs,
    required this.downloadedParagraphs,
    required this.totalSizeBytes,
    required this.downloadedAt,
  });

  @override
  final int? id;
  @override
  final String bookUuid;
  @override
  final int chapterIndex;
  @override
  final String ttsProvider;
  @override
  final String voiceName;
  @override
  final double speechRate;
  @override
  final bool isCompleted;
  @override
  final int totalParagraphs;
  @override
  final int downloadedParagraphs;
  @override
  final int totalSizeBytes;
  @override
  final int downloadedAt;

  @override
  String toString() {
    return 'OfflineTtsRecord(id: $id, bookUuid: $bookUuid, chapterIndex: $chapterIndex, ttsProvider: $ttsProvider, voiceName: $voiceName, speechRate: $speechRate, isCompleted: $isCompleted, totalParagraphs: $totalParagraphs, downloadedParagraphs: $downloadedParagraphs, totalSizeBytes: $totalSizeBytes, downloadedAt: $downloadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfflineTtsRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookUuid, bookUuid) ||
                other.bookUuid == bookUuid) &&
            (identical(other.chapterIndex, chapterIndex) ||
                other.chapterIndex == chapterIndex) &&
            (identical(other.ttsProvider, ttsProvider) ||
                other.ttsProvider == ttsProvider) &&
            (identical(other.voiceName, voiceName) ||
                other.voiceName == voiceName) &&
            (identical(other.speechRate, speechRate) ||
                other.speechRate == speechRate) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.totalParagraphs, totalParagraphs) ||
                other.totalParagraphs == totalParagraphs) &&
            (identical(other.downloadedParagraphs, downloadedParagraphs) ||
                other.downloadedParagraphs == downloadedParagraphs) &&
            (identical(other.totalSizeBytes, totalSizeBytes) ||
                other.totalSizeBytes == totalSizeBytes) &&
            (identical(other.downloadedAt, downloadedAt) ||
                other.downloadedAt == downloadedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookUuid,
    chapterIndex,
    ttsProvider,
    voiceName,
    speechRate,
    isCompleted,
    totalParagraphs,
    downloadedParagraphs,
    totalSizeBytes,
    downloadedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OfflineTtsRecordImplCopyWith<_$OfflineTtsRecordImpl> get copyWith =>
      __$$OfflineTtsRecordImplCopyWithImpl<_$OfflineTtsRecordImpl>(
        this,
        _$identity,
      );
}

abstract class _OfflineTtsRecord implements OfflineTtsRecord {
  const factory _OfflineTtsRecord({
    final int? id,
    required final String bookUuid,
    required final int chapterIndex,
    required final String ttsProvider,
    required final String voiceName,
    required final double speechRate,
    required final bool isCompleted,
    required final int totalParagraphs,
    required final int downloadedParagraphs,
    required final int totalSizeBytes,
    required final int downloadedAt,
  }) = _$OfflineTtsRecordImpl;

  @override
  int? get id;
  @override
  String get bookUuid;
  @override
  int get chapterIndex;
  @override
  String get ttsProvider;
  @override
  String get voiceName;
  @override
  double get speechRate;
  @override
  bool get isCompleted;
  @override
  int get totalParagraphs;
  @override
  int get downloadedParagraphs;
  @override
  int get totalSizeBytes;
  @override
  int get downloadedAt;
  @override
  @JsonKey(ignore: true)
  _$$OfflineTtsRecordImplCopyWith<_$OfflineTtsRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PronunciationRule {
  int? get id => throw _privateConstructorUsedError;
  String get target => throw _privateConstructorUsedError;
  String get replacement => throw _privateConstructorUsedError;
  bool get isRegex => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PronunciationRuleCopyWith<PronunciationRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PronunciationRuleCopyWith<$Res> {
  factory $PronunciationRuleCopyWith(
    PronunciationRule value,
    $Res Function(PronunciationRule) then,
  ) = _$PronunciationRuleCopyWithImpl<$Res, PronunciationRule>;
  @useResult
  $Res call({
    int? id,
    String target,
    String replacement,
    bool isRegex,
    bool active,
  });
}

/// @nodoc
class _$PronunciationRuleCopyWithImpl<$Res, $Val extends PronunciationRule>
    implements $PronunciationRuleCopyWith<$Res> {
  _$PronunciationRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? target = null,
    Object? replacement = null,
    Object? isRegex = null,
    Object? active = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            target: null == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as String,
            replacement: null == replacement
                ? _value.replacement
                : replacement // ignore: cast_nullable_to_non_nullable
                      as String,
            isRegex: null == isRegex
                ? _value.isRegex
                : isRegex // ignore: cast_nullable_to_non_nullable
                      as bool,
            active: null == active
                ? _value.active
                : active // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PronunciationRuleImplCopyWith<$Res>
    implements $PronunciationRuleCopyWith<$Res> {
  factory _$$PronunciationRuleImplCopyWith(
    _$PronunciationRuleImpl value,
    $Res Function(_$PronunciationRuleImpl) then,
  ) = __$$PronunciationRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String target,
    String replacement,
    bool isRegex,
    bool active,
  });
}

/// @nodoc
class __$$PronunciationRuleImplCopyWithImpl<$Res>
    extends _$PronunciationRuleCopyWithImpl<$Res, _$PronunciationRuleImpl>
    implements _$$PronunciationRuleImplCopyWith<$Res> {
  __$$PronunciationRuleImplCopyWithImpl(
    _$PronunciationRuleImpl _value,
    $Res Function(_$PronunciationRuleImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? target = null,
    Object? replacement = null,
    Object? isRegex = null,
    Object? active = null,
  }) {
    return _then(
      _$PronunciationRuleImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        target: null == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as String,
        replacement: null == replacement
            ? _value.replacement
            : replacement // ignore: cast_nullable_to_non_nullable
                  as String,
        isRegex: null == isRegex
            ? _value.isRegex
            : isRegex // ignore: cast_nullable_to_non_nullable
                  as bool,
        active: null == active
            ? _value.active
            : active // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$PronunciationRuleImpl implements _PronunciationRule {
  const _$PronunciationRuleImpl({
    this.id,
    required this.target,
    required this.replacement,
    required this.isRegex,
    required this.active,
  });

  @override
  final int? id;
  @override
  final String target;
  @override
  final String replacement;
  @override
  final bool isRegex;
  @override
  final bool active;

  @override
  String toString() {
    return 'PronunciationRule(id: $id, target: $target, replacement: $replacement, isRegex: $isRegex, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PronunciationRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.replacement, replacement) ||
                other.replacement == replacement) &&
            (identical(other.isRegex, isRegex) || other.isRegex == isRegex) &&
            (identical(other.active, active) || other.active == active));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, target, replacement, isRegex, active);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PronunciationRuleImplCopyWith<_$PronunciationRuleImpl> get copyWith =>
      __$$PronunciationRuleImplCopyWithImpl<_$PronunciationRuleImpl>(
        this,
        _$identity,
      );
}

abstract class _PronunciationRule implements PronunciationRule {
  const factory _PronunciationRule({
    final int? id,
    required final String target,
    required final String replacement,
    required final bool isRegex,
    required final bool active,
  }) = _$PronunciationRuleImpl;

  @override
  int? get id;
  @override
  String get target;
  @override
  String get replacement;
  @override
  bool get isRegex;
  @override
  bool get active;
  @override
  @JsonKey(ignore: true)
  _$$PronunciationRuleImplCopyWith<_$PronunciationRuleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReadingProgress {
  int? get id => throw _privateConstructorUsedError;
  String get bookUuid => throw _privateConstructorUsedError;
  int get currentChapterIndex => throw _privateConstructorUsedError;
  int get currentParagraphIndex => throw _privateConstructorUsedError;
  int get currentCharacterOffset => throw _privateConstructorUsedError;
  int get lastRead => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReadingProgressCopyWith<ReadingProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingProgressCopyWith<$Res> {
  factory $ReadingProgressCopyWith(
    ReadingProgress value,
    $Res Function(ReadingProgress) then,
  ) = _$ReadingProgressCopyWithImpl<$Res, ReadingProgress>;
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int currentChapterIndex,
    int currentParagraphIndex,
    int currentCharacterOffset,
    int lastRead,
  });
}

/// @nodoc
class _$ReadingProgressCopyWithImpl<$Res, $Val extends ReadingProgress>
    implements $ReadingProgressCopyWith<$Res> {
  _$ReadingProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? currentChapterIndex = null,
    Object? currentParagraphIndex = null,
    Object? currentCharacterOffset = null,
    Object? lastRead = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            bookUuid: null == bookUuid
                ? _value.bookUuid
                : bookUuid // ignore: cast_nullable_to_non_nullable
                      as String,
            currentChapterIndex: null == currentChapterIndex
                ? _value.currentChapterIndex
                : currentChapterIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            currentParagraphIndex: null == currentParagraphIndex
                ? _value.currentParagraphIndex
                : currentParagraphIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            currentCharacterOffset: null == currentCharacterOffset
                ? _value.currentCharacterOffset
                : currentCharacterOffset // ignore: cast_nullable_to_non_nullable
                      as int,
            lastRead: null == lastRead
                ? _value.lastRead
                : lastRead // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReadingProgressImplCopyWith<$Res>
    implements $ReadingProgressCopyWith<$Res> {
  factory _$$ReadingProgressImplCopyWith(
    _$ReadingProgressImpl value,
    $Res Function(_$ReadingProgressImpl) then,
  ) = __$$ReadingProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String bookUuid,
    int currentChapterIndex,
    int currentParagraphIndex,
    int currentCharacterOffset,
    int lastRead,
  });
}

/// @nodoc
class __$$ReadingProgressImplCopyWithImpl<$Res>
    extends _$ReadingProgressCopyWithImpl<$Res, _$ReadingProgressImpl>
    implements _$$ReadingProgressImplCopyWith<$Res> {
  __$$ReadingProgressImplCopyWithImpl(
    _$ReadingProgressImpl _value,
    $Res Function(_$ReadingProgressImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookUuid = null,
    Object? currentChapterIndex = null,
    Object? currentParagraphIndex = null,
    Object? currentCharacterOffset = null,
    Object? lastRead = null,
  }) {
    return _then(
      _$ReadingProgressImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        bookUuid: null == bookUuid
            ? _value.bookUuid
            : bookUuid // ignore: cast_nullable_to_non_nullable
                  as String,
        currentChapterIndex: null == currentChapterIndex
            ? _value.currentChapterIndex
            : currentChapterIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        currentParagraphIndex: null == currentParagraphIndex
            ? _value.currentParagraphIndex
            : currentParagraphIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        currentCharacterOffset: null == currentCharacterOffset
            ? _value.currentCharacterOffset
            : currentCharacterOffset // ignore: cast_nullable_to_non_nullable
                  as int,
        lastRead: null == lastRead
            ? _value.lastRead
            : lastRead // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ReadingProgressImpl implements _ReadingProgress {
  const _$ReadingProgressImpl({
    this.id,
    required this.bookUuid,
    required this.currentChapterIndex,
    required this.currentParagraphIndex,
    required this.currentCharacterOffset,
    required this.lastRead,
  });

  @override
  final int? id;
  @override
  final String bookUuid;
  @override
  final int currentChapterIndex;
  @override
  final int currentParagraphIndex;
  @override
  final int currentCharacterOffset;
  @override
  final int lastRead;

  @override
  String toString() {
    return 'ReadingProgress(id: $id, bookUuid: $bookUuid, currentChapterIndex: $currentChapterIndex, currentParagraphIndex: $currentParagraphIndex, currentCharacterOffset: $currentCharacterOffset, lastRead: $lastRead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingProgressImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookUuid, bookUuid) ||
                other.bookUuid == bookUuid) &&
            (identical(other.currentChapterIndex, currentChapterIndex) ||
                other.currentChapterIndex == currentChapterIndex) &&
            (identical(other.currentParagraphIndex, currentParagraphIndex) ||
                other.currentParagraphIndex == currentParagraphIndex) &&
            (identical(other.currentCharacterOffset, currentCharacterOffset) ||
                other.currentCharacterOffset == currentCharacterOffset) &&
            (identical(other.lastRead, lastRead) ||
                other.lastRead == lastRead));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookUuid,
    currentChapterIndex,
    currentParagraphIndex,
    currentCharacterOffset,
    lastRead,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingProgressImplCopyWith<_$ReadingProgressImpl> get copyWith =>
      __$$ReadingProgressImplCopyWithImpl<_$ReadingProgressImpl>(
        this,
        _$identity,
      );
}

abstract class _ReadingProgress implements ReadingProgress {
  const factory _ReadingProgress({
    final int? id,
    required final String bookUuid,
    required final int currentChapterIndex,
    required final int currentParagraphIndex,
    required final int currentCharacterOffset,
    required final int lastRead,
  }) = _$ReadingProgressImpl;

  @override
  int? get id;
  @override
  String get bookUuid;
  @override
  int get currentChapterIndex;
  @override
  int get currentParagraphIndex;
  @override
  int get currentCharacterOffset;
  @override
  int get lastRead;
  @override
  @JsonKey(ignore: true)
  _$$ReadingProgressImplCopyWith<_$ReadingProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

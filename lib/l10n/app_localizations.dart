import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @uploadBook.
  ///
  /// In en, this message translates to:
  /// **'Upload Book'**
  String get uploadBook;

  /// No description provided for @downloadBook.
  ///
  /// In en, this message translates to:
  /// **'Download Book'**
  String get downloadBook;

  /// No description provided for @uploadingBook.
  ///
  /// In en, this message translates to:
  /// **'Uploading book...'**
  String get uploadingBook;

  /// No description provided for @downloadingBook.
  ///
  /// In en, this message translates to:
  /// **'Downloading book...'**
  String get downloadingBook;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully uploaded \"{title}\" to Cloud!'**
  String uploadSuccess(String title);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload book: {error}'**
  String uploadFailed(String error);

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully downloaded \"{title}\" to local!'**
  String downloadSuccess(String title);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download book: {error}'**
  String downloadFailed(String error);

  /// No description provided for @downloadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Book'**
  String get downloadConfirmTitle;

  /// No description provided for @downloadConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download \"{title}\" from Cloud to this device?'**
  String downloadConfirmDesc(String title);

  /// No description provided for @cloudSourceText.
  ///
  /// In en, this message translates to:
  /// **'Cloud Book'**
  String get cloudSourceText;

  /// No description provided for @localSourceText.
  ///
  /// In en, this message translates to:
  /// **'Local Book'**
  String get localSourceText;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Audire Reader'**
  String get appTitle;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchBookHint.
  ///
  /// In en, this message translates to:
  /// **'Search book on shelf...'**
  String get searchBookHint;

  /// No description provided for @sortBooks.
  ///
  /// In en, this message translates to:
  /// **'Sort Books'**
  String get sortBooks;

  /// No description provided for @sortByLastRead.
  ///
  /// In en, this message translates to:
  /// **'Sort by Last Read'**
  String get sortByLastRead;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get sortByTitle;

  /// No description provided for @sortByDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date Added'**
  String get sortByDateAdded;

  /// No description provided for @emptyShelf.
  ///
  /// In en, this message translates to:
  /// **'Your shelf is empty'**
  String get emptyShelf;

  /// No description provided for @importBookHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button to import a book (.epub, .txt, .pdf, .docx)'**
  String get importBookHint;

  /// No description provided for @noBooksMatch.
  ///
  /// In en, this message translates to:
  /// **'No books match your search'**
  String get noBooksMatch;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully!'**
  String get syncCompleted;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {message}'**
  String syncFailed(String message);

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {error}'**
  String syncError(String error);

  /// No description provided for @pleaseConfigureWebdav.
  ///
  /// In en, this message translates to:
  /// **'Please enable and configure WebDAV in Settings first.'**
  String get pleaseConfigureWebdav;

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @deleteBookConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deleteBookConfirm(String title);

  /// No description provided for @successfullyImported.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported \"{title}\"!'**
  String successfullyImported(String title);

  /// No description provided for @failedToImport.
  ///
  /// In en, this message translates to:
  /// **'Failed to import book: {error}'**
  String failedToImport(String error);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String version(String version);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get developerMode;

  /// No description provided for @debugLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get debugLogs;

  /// No description provided for @webdavDebug.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Debug'**
  String get webdavDebug;

  /// No description provided for @databaseInspector.
  ///
  /// In en, this message translates to:
  /// **'Database Inspector'**
  String get databaseInspector;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache & Reset Sync'**
  String get clearCache;

  /// No description provided for @clearCacheSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared and sync data reset successfully.'**
  String get clearCacheSuccess;

  /// No description provided for @clearCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String clearCacheFailed(String error);

  /// No description provided for @hotkeys.
  ///
  /// In en, this message translates to:
  /// **'Hotkeys & Shortcuts'**
  String get hotkeys;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @generalPreferences.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get generalPreferences;

  /// No description provided for @openLastReadOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Open last read book on launch'**
  String get openLastReadOnLaunch;

  /// No description provided for @autoCheckUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto check for updates'**
  String get autoCheckUpdate;

  /// No description provided for @ttsSettings.
  ///
  /// In en, this message translates to:
  /// **'TTS Settings'**
  String get ttsSettings;

  /// No description provided for @ttsProvider.
  ///
  /// In en, this message translates to:
  /// **'TTS Provider'**
  String get ttsProvider;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @webdavSettings.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync Settings'**
  String get webdavSettings;

  /// No description provided for @enableWebdav.
  ///
  /// In en, this message translates to:
  /// **'Enable WebDAV Sync'**
  String get enableWebdav;

  /// No description provided for @webdavUrl.
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL'**
  String get webdavUrl;

  /// No description provided for @webdavUsername.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Username'**
  String get webdavUsername;

  /// No description provided for @webdavPassword.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Password'**
  String get webdavPassword;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection tested successfully!'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed: {error}'**
  String connectionFailed(String error);

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Dictionary'**
  String get dictionary;

  /// No description provided for @developerSettings.
  ///
  /// In en, this message translates to:
  /// **'Developer Settings'**
  String get developerSettings;

  /// No description provided for @checkUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdates;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @sepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get sepia;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @enterDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Enter Device Name'**
  String get enterDeviceName;

  /// No description provided for @syncConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict Detected'**
  String get syncConflictTitle;

  /// No description provided for @syncConflictDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current reading progress conflicts with data from \"{deviceName}\".\n\nCloud: Chapter {cloudChapter}\nLocal: Chapter {localChapter}\n\nWhich progress would you like to keep?'**
  String syncConflictDesc(
    String deviceName,
    String cloudChapter,
    String localChapter,
  );

  /// No description provided for @keepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get keepLocal;

  /// No description provided for @useCloud.
  ///
  /// In en, this message translates to:
  /// **'Use Cloud'**
  String get useCloud;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort options'**
  String get sortOptions;

  /// No description provided for @deleteBook.
  ///
  /// In en, this message translates to:
  /// **'Delete Book'**
  String get deleteBook;

  /// No description provided for @confirmDeleteBook.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDeleteBook(String title);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @readingAppearance.
  ///
  /// In en, this message translates to:
  /// **'Reading Appearance & Typography'**
  String get readingAppearance;

  /// No description provided for @readingTheme.
  ///
  /// In en, this message translates to:
  /// **'Reading Theme'**
  String get readingTheme;

  /// No description provided for @fontStyle.
  ///
  /// In en, this message translates to:
  /// **'Font Style'**
  String get fontStyle;

  /// No description provided for @readingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reading Speed'**
  String get readingSpeed;

  /// No description provided for @languageFilter.
  ///
  /// In en, this message translates to:
  /// **'Language Filter'**
  String get languageFilter;

  /// No description provided for @searchVoice.
  ///
  /// In en, this message translates to:
  /// **'Search Voice'**
  String get searchVoice;

  /// No description provided for @selectVoice.
  ///
  /// In en, this message translates to:
  /// **'Select Voice'**
  String get selectVoice;

  /// No description provided for @managePronunciation.
  ///
  /// In en, this message translates to:
  /// **'Manage Pronunciation Rules'**
  String get managePronunciation;

  /// No description provided for @hotkeyConfigurations.
  ///
  /// In en, this message translates to:
  /// **'Hotkey Configurations'**
  String get hotkeyConfigurations;

  /// No description provided for @customizeHotkeysDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize keyboard shortcuts for system commands and reading controls.'**
  String get customizeHotkeysDesc;

  /// No description provided for @nextParagraph.
  ///
  /// In en, this message translates to:
  /// **'Next Paragraph'**
  String get nextParagraph;

  /// No description provided for @prevParagraph.
  ///
  /// In en, this message translates to:
  /// **'Previous Paragraph'**
  String get prevParagraph;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get nextChapter;

  /// No description provided for @prevChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous Chapter'**
  String get prevChapter;

  /// No description provided for @playPauseTts.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause TTS'**
  String get playPauseTts;

  /// No description provided for @openChapterShelf.
  ///
  /// In en, this message translates to:
  /// **'Open Chapter Shelf'**
  String get openChapterShelf;

  /// No description provided for @openReaderSetting.
  ///
  /// In en, this message translates to:
  /// **'Open Reader Setting'**
  String get openReaderSetting;

  /// No description provided for @bossKey.
  ///
  /// In en, this message translates to:
  /// **'Boss Key'**
  String get bossKey;

  /// No description provided for @bossKeyActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Boss Key Action'**
  String get bossKeyActionLabel;

  /// No description provided for @minimizeWindow.
  ///
  /// In en, this message translates to:
  /// **'Minimize Window'**
  String get minimizeWindow;

  /// No description provided for @hideWindow.
  ///
  /// In en, this message translates to:
  /// **'Hide Window (Completely invisible)'**
  String get hideWindow;

  /// No description provided for @resetHotkeys.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default Hotkeys'**
  String get resetHotkeys;

  /// No description provided for @cloudLibrarySync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Library Sync'**
  String get cloudLibrarySync;

  /// No description provided for @cloudSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Synchronize your novel shelf, cover arts, exact reading progress, and book contents across devices using a private WebDAV server.'**
  String get cloudSyncDesc;

  /// No description provided for @autoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically synchronize reading progress of all books and cloud index.'**
  String get autoSyncDesc;

  /// No description provided for @webdavServerConfig.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Server Configuration'**
  String get webdavServerConfig;

  /// No description provided for @webdavServerUrl.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Server URL'**
  String get webdavServerUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @passwordAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Password / App Password'**
  String get passwordAppPassword;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @developerModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock advanced diagnostic tools, database inspector, and system logs.'**
  String get developerModeDesc;

  /// No description provided for @enableDebugLogsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Debug Logs'**
  String get enableDebugLogsLabel;

  /// No description provided for @debugLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep a history of application logs for troubleshooting.'**
  String get debugLogsDesc;

  /// No description provided for @webdavDebugConsole.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Debug Console'**
  String get webdavDebugConsole;

  /// No description provided for @webdavDebugDesc.
  ///
  /// In en, this message translates to:
  /// **'Output raw WebDAV HTTP requests and responses to system log.'**
  String get webdavDebugDesc;

  /// No description provided for @openDebugConsole.
  ///
  /// In en, this message translates to:
  /// **'Open Debug Console'**
  String get openDebugConsole;

  /// No description provided for @forceSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Force Sync Now'**
  String get forceSyncNow;

  /// No description provided for @synchronizing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing...'**
  String get synchronizing;

  /// No description provided for @processingSync.
  ///
  /// In en, this message translates to:
  /// **'Processing books, cover arts, and reading progress...'**
  String get processingSync;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get allLanguages;

  /// No description provided for @otherLanguages.
  ///
  /// In en, this message translates to:
  /// **'Others (Japanese, French...)'**
  String get otherLanguages;

  /// No description provided for @searchVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search voice name...'**
  String get searchVoiceHint;

  /// No description provided for @systemTtsOffline.
  ///
  /// In en, this message translates to:
  /// **'System TTS (Offline)'**
  String get systemTtsOffline;

  /// No description provided for @edgeTtsOnline.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Edge TTS (Online)'**
  String get edgeTtsOnline;

  /// No description provided for @fillCredentialsHint.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all credentials first.'**
  String get fillCredentialsHint;

  /// No description provided for @connectionSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Connection successful! WebDAV server is active.'**
  String get connectionSuccessDesc;

  /// No description provided for @connectionFailedDesc.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please verify URL, username, and password.'**
  String get connectionFailedDesc;

  /// No description provided for @syncSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Sync Successful'**
  String get syncSuccessful;

  /// No description provided for @resetHotkeysSuccess.
  ///
  /// In en, this message translates to:
  /// **'All hotkeys reset to default values.'**
  String get resetHotkeysSuccess;

  /// No description provided for @recordHotkey.
  ///
  /// In en, this message translates to:
  /// **'Record Hotkey: {keyName}'**
  String recordHotkey(String keyName);

  /// No description provided for @pressHotkeyDesc.
  ///
  /// In en, this message translates to:
  /// **'Press your keyboard combination. Avoid using system reserve keys.'**
  String get pressHotkeyDesc;

  /// No description provided for @pressKeys.
  ///
  /// In en, this message translates to:
  /// **'Press keys...'**
  String get pressKeys;

  /// No description provided for @capturedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Captured successfully!'**
  String get capturedSuccess;

  /// No description provided for @listeningKeystroke.
  ///
  /// In en, this message translates to:
  /// **'Listening for keystroke...'**
  String get listeningKeystroke;

  /// No description provided for @openLastReadDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically resume reading the most recently read book on launch.'**
  String get openLastReadDesc;

  /// No description provided for @autoCheckUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for new versions from GitHub when the app starts.'**
  String get autoCheckUpdateDesc;

  /// No description provided for @enableWebdavFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enable WebDAV Sync first.'**
  String get enableWebdavFirst;

  /// No description provided for @lastSyncedAt.
  ///
  /// In en, this message translates to:
  /// **'Last Synced: {time}'**
  String lastSyncedAt(String time);

  /// No description provided for @lastSyncedNever.
  ///
  /// In en, this message translates to:
  /// **'Last Synced: Never'**
  String get lastSyncedNever;

  /// No description provided for @enterWebdavUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter WebDAV URL'**
  String get enterWebdavUrl;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter Username'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter Password'**
  String get enterPassword;

  /// No description provided for @parsingBookContent.
  ///
  /// In en, this message translates to:
  /// **'Parsing book content...'**
  String get parsingBookContent;

  /// No description provided for @importBook.
  ///
  /// In en, this message translates to:
  /// **'Import Book'**
  String get importBook;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @chaptersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Chapters'**
  String chaptersCount(int count);

  /// No description provided for @readPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Read'**
  String readPercent(String percent);

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @bookmarkAdded.
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// No description provided for @paragraphActions.
  ///
  /// In en, this message translates to:
  /// **'Paragraph Actions'**
  String get paragraphActions;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy Text'**
  String get copyText;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @removeHighlight.
  ///
  /// In en, this message translates to:
  /// **'Remove Highlight'**
  String get removeHighlight;

  /// No description provided for @highlightRemoved.
  ///
  /// In en, this message translates to:
  /// **'Highlight removed'**
  String get highlightRemoved;

  /// No description provided for @highlightSaved.
  ///
  /// In en, this message translates to:
  /// **'Highlight saved'**
  String get highlightSaved;

  /// No description provided for @typeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Type your note here...'**
  String get typeNoteHint;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @noBookActive.
  ///
  /// In en, this message translates to:
  /// **'No book active'**
  String get noBookActive;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// No description provided for @displayTypography.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY & TYPOGRAPHY'**
  String get displayTypography;

  /// No description provided for @textToSpeechTts.
  ///
  /// In en, this message translates to:
  /// **'TEXT-TO-SPEECH (TTS)'**
  String get textToSpeechTts;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer ({time} remaining)'**
  String sleepTimerRemaining(String time);

  /// No description provided for @sleepTimerStopAtEnd.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer (Stop at end of chapter)'**
  String get sleepTimerStopAtEnd;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @endChapter.
  ///
  /// In en, this message translates to:
  /// **'End Chapter'**
  String get endChapter;

  /// No description provided for @audioPanelProgress.
  ///
  /// In en, this message translates to:
  /// **'Paragraph {currentParagraph} of {totalParagraphs} ({percent}%) • Chapter {currentChapter}/{totalChapters} ({chapterPercent}%)'**
  String audioPanelProgress(
    int currentParagraph,
    int totalParagraphs,
    String percent,
    int currentChapter,
    int totalChapters,
    String chapterPercent,
  );

  /// No description provided for @searchInsideBook.
  ///
  /// In en, this message translates to:
  /// **'Search Inside Book'**
  String get searchInsideBook;

  /// No description provided for @typeKeyword.
  ///
  /// In en, this message translates to:
  /// **'Type keyword...'**
  String get typeKeyword;

  /// No description provided for @enterKeywordToSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to start searching'**
  String get enterKeywordToSearch;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @chaptersTab.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTab;

  /// No description provided for @bookmarksTab.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTab;

  /// No description provided for @highlightsTab.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get highlightsTab;

  /// No description provided for @searchChaptersHint.
  ///
  /// In en, this message translates to:
  /// **'Search chapters...'**
  String get searchChaptersHint;

  /// No description provided for @noChaptersMatch.
  ///
  /// In en, this message translates to:
  /// **'No chapters match your search'**
  String get noChaptersMatch;

  /// No description provided for @noBookmarksSaved.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks saved yet'**
  String get noBookmarksSaved;

  /// No description provided for @paragraphIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Paragraph {index}'**
  String paragraphIndexLabel(int index);

  /// No description provided for @noHighlightsSaved.
  ///
  /// In en, this message translates to:
  /// **'No highlights saved yet'**
  String get noHighlightsSaved;

  /// No description provided for @failedToLoadRules.
  ///
  /// In en, this message translates to:
  /// **'Failed to load rules: {error}'**
  String failedToLoadRules(String error);

  /// No description provided for @ruleDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rule deleted successfully'**
  String get ruleDeletedSuccessfully;

  /// No description provided for @failedToDeleteRule.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete rule: {error}'**
  String failedToDeleteRule(String error);

  /// No description provided for @failedToUpdateRule.
  ///
  /// In en, this message translates to:
  /// **'Failed to update rule: {error}'**
  String failedToUpdateRule(String error);

  /// No description provided for @addPronunciationRule.
  ///
  /// In en, this message translates to:
  /// **'Add Pronunciation Rule'**
  String get addPronunciationRule;

  /// No description provided for @editPronunciationRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Pronunciation Rule'**
  String get editPronunciationRule;

  /// No description provided for @originalTextTarget.
  ///
  /// In en, this message translates to:
  /// **'Original Text (Target)'**
  String get originalTextTarget;

  /// No description provided for @readAsReplacement.
  ///
  /// In en, this message translates to:
  /// **'Read As (Replacement)'**
  String get readAsReplacement;

  /// No description provided for @useRegularExpressionRegex.
  ///
  /// In en, this message translates to:
  /// **'Use Regular Expression (Regex)'**
  String get useRegularExpressionRegex;

  /// No description provided for @advancedPatternMatching.
  ///
  /// In en, this message translates to:
  /// **'Advanced pattern matching'**
  String get advancedPatternMatching;

  /// No description provided for @pleaseFillBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields'**
  String get pleaseFillBothFields;

  /// No description provided for @ruleAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rule added successfully'**
  String get ruleAddedSuccessfully;

  /// No description provided for @ruleUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rule updated successfully'**
  String get ruleUpdatedSuccessfully;

  /// No description provided for @failedToSaveRule.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rule: {error}'**
  String failedToSaveRule(String error);

  /// No description provided for @confirmDeleteRuleTarget.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the rule for \"{target}\"?'**
  String confirmDeleteRuleTarget(String target);

  /// No description provided for @noCustomPronunciationRules.
  ///
  /// In en, this message translates to:
  /// **'No custom pronunciation rules'**
  String get noCustomPronunciationRules;

  /// No description provided for @tapToAddFirstRule.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button to add your first rule'**
  String get tapToAddFirstRule;

  /// No description provided for @regex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get regex;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @debugConsole.
  ///
  /// In en, this message translates to:
  /// **'Debug Console'**
  String get debugConsole;

  /// No description provided for @copyAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy All Logs'**
  String get copyAllLogs;

  /// No description provided for @allLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'All logs copied to clipboard.'**
  String get allLogsCopied;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @consoleLogsCleared.
  ///
  /// In en, this message translates to:
  /// **'Console logs cleared.'**
  String get consoleLogsCleared;

  /// No description provided for @searchLogsHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get searchLogsHint;

  /// No description provided for @noMatchingLogs.
  ///
  /// In en, this message translates to:
  /// **'No matching logs found'**
  String get noMatchingLogs;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND MUSIC (BGM)'**
  String get backgroundMusic;

  /// No description provided for @enableBgm.
  ///
  /// In en, this message translates to:
  /// **'Enable Background Music'**
  String get enableBgm;

  /// No description provided for @bgmVolume.
  ///
  /// In en, this message translates to:
  /// **'BGM Volume'**
  String get bgmVolume;

  /// No description provided for @bgmLoopMode.
  ///
  /// In en, this message translates to:
  /// **'BGM Loop Mode'**
  String get bgmLoopMode;

  /// No description provided for @bgmSourceType.
  ///
  /// In en, this message translates to:
  /// **'Source Type'**
  String get bgmSourceType;

  /// No description provided for @bgmSourceUrl.
  ///
  /// In en, this message translates to:
  /// **'BGM Link / Video ID'**
  String get bgmSourceUrl;

  /// No description provided for @bgmSourceUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter URL or video ID...'**
  String get bgmSourceUrlHint;

  /// No description provided for @addBgmTrack.
  ///
  /// In en, this message translates to:
  /// **'Add BGM Track'**
  String get addBgmTrack;

  /// No description provided for @trackName.
  ///
  /// In en, this message translates to:
  /// **'Track Name'**
  String get trackName;

  /// No description provided for @selectLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectLocalFile;

  /// No description provided for @addOnline.
  ///
  /// In en, this message translates to:
  /// **'Add Online (Stream)'**
  String get addOnline;

  /// No description provided for @downloadOffline.
  ///
  /// In en, this message translates to:
  /// **'Download Offline'**
  String get downloadOffline;

  /// No description provided for @noLoop.
  ///
  /// In en, this message translates to:
  /// **'No Loop'**
  String get noLoop;

  /// No description provided for @loopOne.
  ///
  /// In en, this message translates to:
  /// **'Loop One Track'**
  String get loopOne;

  /// No description provided for @loopPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Loop Playlist'**
  String get loopPlaylist;

  /// No description provided for @noBgmTracks.
  ///
  /// In en, this message translates to:
  /// **'No background music tracks added yet'**
  String get noBgmTracks;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {percent}%'**
  String downloading(String percent);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @forcePush.
  ///
  /// In en, this message translates to:
  /// **'Force Push (Local -> Cloud)'**
  String get forcePush;

  /// No description provided for @forcePull.
  ///
  /// In en, this message translates to:
  /// **'Force Pull (Cloud -> Local)'**
  String get forcePull;

  /// No description provided for @forcePushConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Push'**
  String get forcePushConfirmTitle;

  /// No description provided for @forcePushConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will overwrite all data on the cloud server with the data from this device. Are you sure you want to continue?'**
  String get forcePushConfirmDesc;

  /// No description provided for @forcePullConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Pull'**
  String get forcePullConfirmTitle;

  /// No description provided for @forcePullConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will overwrite all data on this device with the data from the cloud server. Local books and progress not on the cloud will be deleted. Are you sure you want to continue?'**
  String get forcePullConfirmDesc;

  /// No description provided for @forcePushSuccess.
  ///
  /// In en, this message translates to:
  /// **'Force push completed successfully!'**
  String get forcePushSuccess;

  /// No description provided for @forcePullSuccess.
  ///
  /// In en, this message translates to:
  /// **'Force pull completed successfully!'**
  String get forcePullSuccess;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @onlySyncProgress.
  ///
  /// In en, this message translates to:
  /// **'Only overwrite reading progress'**
  String get onlySyncProgress;

  /// No description provided for @onlySyncProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Quickly sync reading progress without modifying book shelf.'**
  String get onlySyncProgressDesc;

  /// No description provided for @searchStation.
  ///
  /// In en, this message translates to:
  /// **'Search stations...'**
  String get searchStation;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link URL'**
  String get addLink;

  /// No description provided for @trackUrl.
  ///
  /// In en, this message translates to:
  /// **'Link URL'**
  String get trackUrl;

  /// No description provided for @editTrack.
  ///
  /// In en, this message translates to:
  /// **'Edit Track Info'**
  String get editTrack;

  /// No description provided for @addSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added to library successfully!'**
  String get addSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully!'**
  String get updateSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully!'**
  String get deleteSuccess;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'No matching results found'**
  String get emptySearch;

  /// No description provided for @addFileOption.
  ///
  /// In en, this message translates to:
  /// **'Select local file'**
  String get addFileOption;

  /// No description provided for @addLinkOption.
  ///
  /// In en, this message translates to:
  /// **'Paste direct link'**
  String get addLinkOption;

  /// No description provided for @importTrack.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get importTrack;

  /// No description provided for @forcePushBook.
  ///
  /// In en, this message translates to:
  /// **'Force Push Book'**
  String get forcePushBook;

  /// No description provided for @forcePullBook.
  ///
  /// In en, this message translates to:
  /// **'Force Pull Book'**
  String get forcePullBook;

  /// No description provided for @forcePushBookConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Push Book'**
  String get forcePushBookConfirmTitle;

  /// No description provided for @forcePushBookConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will overwrite this book and its reading progress on the WebDAV cloud. Are you sure you want to continue?'**
  String get forcePushBookConfirmDesc;

  /// No description provided for @forcePullBookConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Force Pull Book'**
  String get forcePullBookConfirmTitle;

  /// No description provided for @forcePullBookConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will download this book and its reading progress from the WebDAV cloud to overwrite local data. Are you sure you want to continue?'**
  String get forcePullBookConfirmDesc;

  /// No description provided for @forcePushBookSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully pushed book \"{title}\" to cloud.'**
  String forcePushBookSuccess(String title);

  /// No description provided for @forcePullBookSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully pulled book \"{title}\" to local.'**
  String forcePullBookSuccess(String title);

  /// No description provided for @forcePushBookFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to push book: {error}'**
  String forcePushBookFailed(String error);

  /// No description provided for @forcePullBookFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pull book: {error}'**
  String forcePullBookFailed(String error);

  /// No description provided for @enableWebdavDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync library via private WebDAV server'**
  String get enableWebdavDesc;

  /// No description provided for @autoSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync WebDAV'**
  String get autoSyncEnabled;

  /// No description provided for @autoSyncEnabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically synchronize library on app launch or reader screen exit.'**
  String get autoSyncEnabledDesc;

  /// No description provided for @deleteDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from Device'**
  String get deleteDevice;

  /// No description provided for @deleteCloud.
  ///
  /// In en, this message translates to:
  /// **'Delete from Cloud'**
  String get deleteCloud;

  /// No description provided for @uploadCloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to Cloud'**
  String get uploadCloud;

  /// No description provided for @localSource.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localSource;

  /// No description provided for @cloudSource.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get cloudSource;

  /// No description provided for @syncProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync Progress'**
  String get syncProgress;

  /// No description provided for @autoSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync (Sync Now)'**
  String get autoSyncTitle;

  /// No description provided for @forcePushDesc.
  ///
  /// In en, this message translates to:
  /// **'Force push all local book files and reading progress to WebDAV Cloud.'**
  String get forcePushDesc;

  /// No description provided for @forcePullDesc.
  ///
  /// In en, this message translates to:
  /// **'Force pull all book files and reading progress from WebDAV Cloud to overwrite local data.'**
  String get forcePullDesc;

  /// No description provided for @syncBookProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Synchronize reading progress of book \"{title}\"'**
  String syncBookProgressDesc(Object title);

  /// No description provided for @forcePushProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Overwrite the current reading progress of this device to Cloud WebDAV.'**
  String get forcePushProgressDesc;

  /// No description provided for @forcePullProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Pull the reading progress from Cloud WebDAV to this device.'**
  String get forcePullProgressDesc;

  /// No description provided for @deleteLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local Only'**
  String get deleteLocalOnly;

  /// No description provided for @deleteBothLocalAndCloud.
  ///
  /// In en, this message translates to:
  /// **'Both Local & Cloud'**
  String get deleteBothLocalAndCloud;

  /// No description provided for @deleteBookOptionsContent.
  ///
  /// In en, this message translates to:
  /// **'How do you want to delete \"{title}\"?\n\n• Local Only: Delete caches on this device, keep it on WebDAV Cloud to download later.\n• Both Local & Cloud: Permanently delete from both this device and WebDAV Cloud.'**
  String deleteBookOptionsContent(String title);

  /// No description provided for @deletedFromLocal.
  ///
  /// In en, this message translates to:
  /// **'Deleted from Local'**
  String get deletedFromLocal;

  /// No description provided for @deletedFromBoth.
  ///
  /// In en, this message translates to:
  /// **'Deleted from both Local & Cloud'**
  String get deletedFromBoth;

  /// No description provided for @deleteFromCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete from Cloud'**
  String get deleteFromCloudTitle;

  /// No description provided for @confirmDeleteFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\" from WebDAV Cloud? Since this book is not downloaded, this action will permanently delete it.'**
  String confirmDeleteFromCloud(String title);

  /// No description provided for @requestedDeletionFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Requested deletion from Cloud'**
  String get requestedDeletionFromCloud;

  /// No description provided for @deleteBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Book'**
  String get deleteBookTitle;

  /// No description provided for @bookNotOnCloudCannotPull.
  ///
  /// In en, this message translates to:
  /// **'This book has never been uploaded to the cloud. Cannot pull data.'**
  String get bookNotOnCloudCannotPull;

  /// No description provided for @bookNotOnCloudPushFull.
  ///
  /// In en, this message translates to:
  /// **'This book does not exist on the cloud. The entire book file and reading progress will be uploaded.'**
  String get bookNotOnCloudPushFull;

  /// No description provided for @qrDeviceSync.
  ///
  /// In en, this message translates to:
  /// **'Quick Device Sync (QR)'**
  String get qrDeviceSync;

  /// No description provided for @qrSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Device Sync (QR)'**
  String get qrSyncTitle;

  /// No description provided for @qrSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose synchronization action between your devices.'**
  String get qrSyncDesc;

  /// No description provided for @receiveConfig.
  ///
  /// In en, this message translates to:
  /// **'Receive Configuration (Receive)'**
  String get receiveConfig;

  /// No description provided for @receiveConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Show QR code to receive configuration (No Camera required)'**
  String get receiveConfigDesc;

  /// No description provided for @shareConfig.
  ///
  /// In en, this message translates to:
  /// **'Share Configuration (Share)'**
  String get shareConfig;

  /// No description provided for @shareConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan receiver\'\'s QR code and send configuration'**
  String get shareConfigDesc;

  /// No description provided for @shareConfigQrScanner.
  ///
  /// In en, this message translates to:
  /// **'Share Configuration (Scan QR)'**
  String get shareConfigQrScanner;

  /// No description provided for @needCameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required to scan QR code'**
  String get needCameraPermission;

  /// No description provided for @cameraPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Please grant camera permission to the app in Device Settings to continue.'**
  String get cameraPermissionDesc;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @scanQrCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point camera at the receiver\'\'s QR code to connect'**
  String get scanQrCodeInstruction;

  /// No description provided for @sendingConfig.
  ///
  /// In en, this message translates to:
  /// **'Sending configuration to receiver...'**
  String get sendingConfig;

  /// No description provided for @shareConfigSuccess.
  ///
  /// In en, this message translates to:
  /// **'Configuration shared successfully!'**
  String get shareConfigSuccess;

  /// No description provided for @sendConfigErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Configuration Error'**
  String get sendConfigErrorTitle;

  /// No description provided for @sendConfigErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect and transfer configuration to receiver. Details: {error}'**
  String sendConfigErrorDesc(String error);

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Re-scan'**
  String get rescan;

  /// No description provided for @receiveConfigQr.
  ///
  /// In en, this message translates to:
  /// **'Receive Configuration via QR'**
  String get receiveConfigQr;

  /// No description provided for @receiverDevice.
  ///
  /// In en, this message translates to:
  /// **'Receiver Device'**
  String get receiverDevice;

  /// No description provided for @receiverDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Use another device to scan the QR code below to automatically transfer sync configuration to this machine.'**
  String get receiverDeviceDesc;

  /// No description provided for @connectingTunnel.
  ///
  /// In en, this message translates to:
  /// **'Connecting SSH tunnel (localhost.run)...'**
  String get connectingTunnel;

  /// No description provided for @failedToInitTunnel.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize Tunnel. Please check network connection or try again later.'**
  String get failedToInitTunnel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @applyingConfig.
  ///
  /// In en, this message translates to:
  /// **'Applying configuration and syncing...'**
  String get applyingConfig;

  /// No description provided for @webdavConnectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'WebDAV connection successful! Syncing library...'**
  String get webdavConnectionSuccess;

  /// No description provided for @librarySyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Library synced successfully!'**
  String get librarySyncSuccess;

  /// No description provided for @librarySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Library sync failed: {message}'**
  String librarySyncFailed(String message);

  /// No description provided for @webdavConnectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Connection Error'**
  String get webdavConnectionErrorTitle;

  /// No description provided for @webdavConnectionErrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Configuration received from \"{deviceName}\", but failed to connect to WebDAV server. Please verify configuration on WebDAV server.'**
  String webdavConnectionErrorDesc(String deviceName);

  /// No description provided for @applyConfigError.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply configuration: {error}'**
  String applyConfigError(String error);

  /// No description provided for @bgmLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Local File'**
  String get bgmLocalFile;

  /// No description provided for @bgmPasteLink.
  ///
  /// In en, this message translates to:
  /// **'Paste Link'**
  String get bgmPasteLink;

  /// No description provided for @bgmInternetRadio.
  ///
  /// In en, this message translates to:
  /// **'Internet Radio'**
  String get bgmInternetRadio;

  /// No description provided for @bgmLofiSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Lofi Suggestions'**
  String get bgmLofiSuggestions;

  /// No description provided for @assistiveButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'ASSISTIVE BUTTON'**
  String get assistiveButtonTitle;

  /// No description provided for @showAssistiveButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Show floating assistive button'**
  String get showAssistiveButtonLabel;

  /// No description provided for @singleTapLabel.
  ///
  /// In en, this message translates to:
  /// **'Single Tap'**
  String get singleTapLabel;

  /// No description provided for @doubleTapLabel.
  ///
  /// In en, this message translates to:
  /// **'Double Tap'**
  String get doubleTapLabel;

  /// No description provided for @longPressLabel.
  ///
  /// In en, this message translates to:
  /// **'Long Press'**
  String get longPressLabel;

  /// No description provided for @resetButtonPosition.
  ///
  /// In en, this message translates to:
  /// **'Reset Button Position'**
  String get resetButtonPosition;

  /// No description provided for @resetButtonPositionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Floating button position reset to default'**
  String get resetButtonPositionSuccess;

  /// No description provided for @actionNone.
  ///
  /// In en, this message translates to:
  /// **'Do nothing'**
  String get actionNone;

  /// No description provided for @actionNextParagraph.
  ///
  /// In en, this message translates to:
  /// **'Next Paragraph'**
  String get actionNextParagraph;

  /// No description provided for @actionPrevParagraph.
  ///
  /// In en, this message translates to:
  /// **'Prev Paragraph'**
  String get actionPrevParagraph;

  /// No description provided for @actionPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get actionPlayPause;

  /// No description provided for @actionNextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get actionNextChapter;

  /// No description provided for @actionPrevChapter.
  ///
  /// In en, this message translates to:
  /// **'Prev Chapter'**
  String get actionPrevChapter;

  /// No description provided for @actionOpenTtsSettings.
  ///
  /// In en, this message translates to:
  /// **'Open TTS Settings'**
  String get actionOpenTtsSettings;

  /// No description provided for @actionOpenBgmSettings.
  ///
  /// In en, this message translates to:
  /// **'Open BGM Settings'**
  String get actionOpenBgmSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

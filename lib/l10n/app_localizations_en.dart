// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Audire Reader';

  @override
  String get library => 'Library';

  @override
  String get settings => 'Settings';

  @override
  String get searchBookHint => 'Search book on shelf...';

  @override
  String get sortBooks => 'Sort Books';

  @override
  String get sortByLastRead => 'Sort by Last Read';

  @override
  String get sortByTitle => 'Sort by Title';

  @override
  String get sortByDateAdded => 'Sort by Date Added';

  @override
  String get emptyShelf => 'Your shelf is empty';

  @override
  String get importBookHint =>
      'Tap the \"+\" button to import a book (.epub, .txt, .pdf, .docx)';

  @override
  String get noBooksMatch => 'No books match your search';

  @override
  String get syncCompleted => 'Sync completed successfully!';

  @override
  String syncFailed(String message) {
    return 'Sync failed: $message';
  }

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get pleaseConfigureWebdav =>
      'Please enable and configure WebDAV in Settings first.';

  @override
  String get neverSynced => 'Never synced';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String deleteBookConfirm(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String successfullyImported(String title) {
    return 'Successfully imported \"$title\"!';
  }

  @override
  String failedToImport(String error) {
    return 'Failed to import book: $error';
  }

  @override
  String get unread => 'Unread';

  @override
  String get reading => 'Reading';

  @override
  String get completed => 'Completed';

  @override
  String get all => 'All';

  @override
  String get aboutApp => 'About App';

  @override
  String version(String version) {
    return 'Version: $version';
  }

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get developerMode => 'Developer Mode';

  @override
  String get debugLogs => 'Debug Logs';

  @override
  String get webdavDebug => 'WebDAV Debug';

  @override
  String get databaseInspector => 'Database Inspector';

  @override
  String get clearCache => 'Clear Cache & Reset Sync';

  @override
  String get clearCacheSuccess =>
      'Cache cleared and sync data reset successfully.';

  @override
  String clearCacheFailed(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get hotkeys => 'Hotkeys & Shortcuts';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get generalPreferences => 'General Preferences';

  @override
  String get openLastReadOnLaunch => 'Open last read book on launch';

  @override
  String get autoCheckUpdate => 'Auto check for updates';

  @override
  String get ttsSettings => 'TTS Settings';

  @override
  String get ttsProvider => 'TTS Provider';

  @override
  String get voice => 'Voice';

  @override
  String get speed => 'Speed';

  @override
  String get fontSize => 'Font Size';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get webdavSettings => 'WebDAV Sync Settings';

  @override
  String get enableWebdav => 'Enable WebDAV Sync';

  @override
  String get webdavUrl => 'WebDAV URL';

  @override
  String get webdavUsername => 'WebDAV Username';

  @override
  String get webdavPassword => 'WebDAV Password';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccess => 'Connection tested successfully!';

  @override
  String connectionFailed(String error) {
    return 'Connection test failed: $error';
  }

  @override
  String get dictionary => 'Pronunciation Dictionary';

  @override
  String get developerSettings => 'Developer Settings';

  @override
  String get checkUpdates => 'Check for Updates';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get sepia => 'Sepia';

  @override
  String get sortOptions => 'Sort options';

  @override
  String get deleteBook => 'Delete Book';

  @override
  String confirmDeleteBook(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get readingAppearance => 'Reading Appearance & Typography';

  @override
  String get readingTheme => 'Reading Theme';

  @override
  String get fontStyle => 'Font Style';

  @override
  String get readingSpeed => 'Reading Speed';

  @override
  String get languageFilter => 'Language Filter';

  @override
  String get searchVoice => 'Search Voice';

  @override
  String get selectVoice => 'Select Voice';

  @override
  String get managePronunciation => 'Manage Pronunciation Rules';

  @override
  String get hotkeyConfigurations => 'Hotkey Configurations';

  @override
  String get customizeHotkeysDesc =>
      'Customize keyboard shortcuts for system commands and reading controls.';

  @override
  String get nextParagraph => 'Next Paragraph';

  @override
  String get prevParagraph => 'Previous Paragraph';

  @override
  String get nextChapter => 'Next Chapter';

  @override
  String get prevChapter => 'Previous Chapter';

  @override
  String get playPauseTts => 'Play/Pause TTS';

  @override
  String get openChapterShelf => 'Open Chapter Shelf';

  @override
  String get openReaderSetting => 'Open Reader Setting';

  @override
  String get bossKey => 'Boss Key';

  @override
  String get bossKeyActionLabel => 'Boss Key Action';

  @override
  String get minimizeWindow => 'Minimize Window';

  @override
  String get hideWindow => 'Hide Window (Completely invisible)';

  @override
  String get resetHotkeys => 'Reset to Default Hotkeys';

  @override
  String get cloudLibrarySync => 'Cloud Library Sync';

  @override
  String get cloudSyncDesc =>
      'Synchronize your novel shelf, cover arts, exact reading progress, and book contents across devices using a private WebDAV server.';

  @override
  String get autoSyncDesc => 'Auto-sync when launching or leaving a book';

  @override
  String get webdavServerConfig => 'WebDAV Server Configuration';

  @override
  String get webdavServerUrl => 'WebDAV Server URL';

  @override
  String get username => 'Username';

  @override
  String get passwordAppPassword => 'Password / App Password';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get developerModeDesc =>
      'Unlock advanced diagnostic tools, database inspector, and system logs.';

  @override
  String get enableDebugLogsLabel => 'Enable Debug Logs';

  @override
  String get debugLogsDesc =>
      'Keep a history of application logs for troubleshooting.';

  @override
  String get webdavDebugConsole => 'WebDAV Debug Console';

  @override
  String get webdavDebugDesc =>
      'Output raw WebDAV HTTP requests and responses to system log.';

  @override
  String get openDebugConsole => 'Open Debug Console';

  @override
  String get forceSyncNow => 'Force Sync Now';

  @override
  String get synchronizing => 'Synchronizing...';

  @override
  String get processingSync =>
      'Processing books, cover arts, and reading progress...';

  @override
  String get allLanguages => 'All Languages';

  @override
  String get otherLanguages => 'Others (Japanese, French...)';

  @override
  String get searchVoiceHint => 'Type to search voice name...';

  @override
  String get systemTtsOffline => 'System TTS (Offline)';

  @override
  String get edgeTtsOnline => 'Microsoft Edge TTS (Online)';

  @override
  String get fillCredentialsHint => 'Please fill in all credentials first.';

  @override
  String get connectionSuccessDesc =>
      'Connection successful! WebDAV server is active.';

  @override
  String get connectionFailedDesc =>
      'Connection failed. Please verify URL, username, and password.';

  @override
  String get syncSuccessful => 'Sync Successful';

  @override
  String get resetHotkeysSuccess => 'All hotkeys reset to default values.';

  @override
  String recordHotkey(String keyName) {
    return 'Record Hotkey: $keyName';
  }

  @override
  String get pressHotkeyDesc =>
      'Press your keyboard combination. Avoid using system reserve keys.';

  @override
  String get pressKeys => 'Press keys...';

  @override
  String get capturedSuccess => 'Captured successfully!';

  @override
  String get listeningKeystroke => 'Listening for keystroke...';

  @override
  String get openLastReadDesc =>
      'Automatically resume reading the most recently read book on launch.';

  @override
  String get autoCheckUpdateDesc =>
      'Automatically check for new versions from GitHub when the app starts.';

  @override
  String get enableWebdavFirst => 'Please enable WebDAV Sync first.';

  @override
  String lastSyncedAt(String time) {
    return 'Last Synced: $time';
  }

  @override
  String get lastSyncedNever => 'Last Synced: Never';

  @override
  String get enterWebdavUrl => 'Please enter WebDAV URL';

  @override
  String get enterUsername => 'Please enter Username';

  @override
  String get enterPassword => 'Please enter Password';

  @override
  String get parsingBookContent => 'Parsing book content...';

  @override
  String get importBook => 'Import Book';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String chaptersCount(int count) {
    return '$count Chapters';
  }

  @override
  String readPercent(String percent) {
    return '$percent% Read';
  }

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get paragraphActions => 'Paragraph Actions';

  @override
  String get editNote => 'Edit Note';

  @override
  String get addNote => 'Add Note';

  @override
  String get copyText => 'Copy Text';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get removeHighlight => 'Remove Highlight';

  @override
  String get highlightRemoved => 'Highlight removed';

  @override
  String get highlightSaved => 'Highlight saved';

  @override
  String get typeNoteHint => 'Type your note here...';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get noBookActive => 'No book active';

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get displayTypography => 'DISPLAY & TYPOGRAPHY';

  @override
  String get textToSpeechTts => 'TEXT-TO-SPEECH (TTS)';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String sleepTimerRemaining(String time) {
    return 'Sleep Timer ($time remaining)';
  }

  @override
  String get sleepTimerStopAtEnd => 'Sleep Timer (Stop at end of chapter)';

  @override
  String get off => 'Off';

  @override
  String get endChapter => 'End Chapter';

  @override
  String audioPanelProgress(
    int currentParagraph,
    int totalParagraphs,
    String percent,
    int currentChapter,
    int totalChapters,
    String chapterPercent,
  ) {
    return 'Paragraph $currentParagraph of $totalParagraphs ($percent%) • Chapter $currentChapter/$totalChapters ($chapterPercent%)';
  }

  @override
  String get searchInsideBook => 'Search Inside Book';

  @override
  String get typeKeyword => 'Type keyword...';

  @override
  String get enterKeywordToSearch => 'Enter a keyword to start searching';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get chaptersTab => 'Chapters';

  @override
  String get bookmarksTab => 'Bookmarks';

  @override
  String get highlightsTab => 'Highlights';

  @override
  String get searchChaptersHint => 'Search chapters...';

  @override
  String get noChaptersMatch => 'No chapters match your search';

  @override
  String get noBookmarksSaved => 'No bookmarks saved yet';

  @override
  String paragraphIndexLabel(int index) {
    return 'Paragraph $index';
  }

  @override
  String get noHighlightsSaved => 'No highlights saved yet';

  @override
  String failedToLoadRules(String error) {
    return 'Failed to load rules: $error';
  }

  @override
  String get ruleDeletedSuccessfully => 'Rule deleted successfully';

  @override
  String failedToDeleteRule(String error) {
    return 'Failed to delete rule: $error';
  }

  @override
  String failedToUpdateRule(String error) {
    return 'Failed to update rule: $error';
  }

  @override
  String get addPronunciationRule => 'Add Pronunciation Rule';

  @override
  String get editPronunciationRule => 'Edit Pronunciation Rule';

  @override
  String get originalTextTarget => 'Original Text (Target)';

  @override
  String get readAsReplacement => 'Read As (Replacement)';

  @override
  String get useRegularExpressionRegex => 'Use Regular Expression (Regex)';

  @override
  String get advancedPatternMatching => 'Advanced pattern matching';

  @override
  String get pleaseFillBothFields => 'Please fill in both fields';

  @override
  String get ruleAddedSuccessfully => 'Rule added successfully';

  @override
  String get ruleUpdatedSuccessfully => 'Rule updated successfully';

  @override
  String failedToSaveRule(String error) {
    return 'Failed to save rule: $error';
  }

  @override
  String confirmDeleteRuleTarget(String target) {
    return 'Are you sure you want to delete the rule for \"$target\"?';
  }

  @override
  String get noCustomPronunciationRules => 'No custom pronunciation rules';

  @override
  String get tapToAddFirstRule => 'Tap the \"+\" button to add your first rule';

  @override
  String get regex => 'Regex';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get debugConsole => 'Debug Console';

  @override
  String get copyAllLogs => 'Copy All Logs';

  @override
  String get allLogsCopied => 'All logs copied to clipboard.';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get consoleLogsCleared => 'Console logs cleared.';

  @override
  String get searchLogsHint => 'Search logs...';

  @override
  String get noMatchingLogs => 'No matching logs found';

  @override
  String get backgroundMusic => 'BACKGROUND MUSIC (BGM)';

  @override
  String get enableBgm => 'Enable Background Music';

  @override
  String get bgmVolume => 'BGM Volume';

  @override
  String get bgmLoopMode => 'BGM Loop Mode';

  @override
  String get bgmSourceType => 'Source Type';

  @override
  String get bgmSourceUrl => 'BGM Link / Video ID';

  @override
  String get bgmSourceUrlHint => 'Enter URL or video ID...';

  @override
  String get addBgmTrack => 'Add BGM Track';

  @override
  String get trackName => 'Track Name';

  @override
  String get selectLocalFile => 'Select File';

  @override
  String get addOnline => 'Add Online (Stream)';

  @override
  String get downloadOffline => 'Download Offline';

  @override
  String get noLoop => 'No Loop';

  @override
  String get loopOne => 'Loop One Track';

  @override
  String get loopPlaylist => 'Loop Playlist';

  @override
  String get noBgmTracks => 'No background music tracks added yet';

  @override
  String downloading(String percent) {
    return 'Downloading... $percent%';
  }

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';
}

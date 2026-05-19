//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_service
import audio_session
import audioplayers_darwin
import file_picker
import flutter_tts
import hotkey_manager_macos
import isar_flutter_libs
import package_info_plus
import screen_retriever_macos
import sqflite_darwin
import tray_manager
import url_launcher_macos
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioServicePlugin.register(with: registry.registrar(forPlugin: "AudioServicePlugin"))
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  AudioplayersDarwinPlugin.register(with: registry.registrar(forPlugin: "AudioplayersDarwinPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FlutterTtsPlugin.register(with: registry.registrar(forPlugin: "FlutterTtsPlugin"))
  HotkeyManagerMacosPlugin.register(with: registry.registrar(forPlugin: "HotkeyManagerMacosPlugin"))
  IsarFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "IsarFlutterLibsPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  ScreenRetrieverMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverMacosPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  TrayManagerPlugin.register(with: registry.registrar(forPlugin: "TrayManagerPlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}

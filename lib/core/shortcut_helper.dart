import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class ShortcutHelper {
  // Parse chuỗi phím tắt lưu trữ thành ShortcutActivator
  static ShortcutActivator parse(String shortcutStr) {
    if (shortcutStr.isEmpty || shortcutStr == 'None') {
      // Sử dụng F24 làm fallback an toàn (vì LogicalKeyboardKey không có none)
      return const SingleActivator(LogicalKeyboardKey.f24);
    }
    
    final parts = shortcutStr.split('+');
    bool control = false;
    bool shift = false;
    bool alt = false;
    bool meta = false;
    LogicalKeyboardKey key = LogicalKeyboardKey.f24;

    for (var part in parts) {
      part = part.trim().toLowerCase();
      if (part == 'control' || part == 'ctrl') {
        control = true;
      } else if (part == 'shift') {
        shift = true;
      } else if (part == 'alt') {
        alt = true;
      } else if (part == 'meta' || part == 'win' || part == 'cmd') {
        meta = true;
      } else {
        key = _parseKey(part);
      }
    }

    return SingleActivator(
      key,
      control: control,
      shift: shift,
      alt: alt,
      meta: meta,
    );
  }

  // Chuyển chuỗi phím tắt thành HotKey của hệ điều hành
  static HotKey? parseToGlobalHotKey(String shortcutStr) {
    if (shortcutStr.isEmpty || shortcutStr == 'None') {
      return null;
    }

    final parts = shortcutStr.split('+');
    List<HotKeyModifier> modifiers = [];
    LogicalKeyboardKey key = LogicalKeyboardKey.f24; // fallback

    for (var part in parts) {
      part = part.trim().toLowerCase();
      if (part == 'control' || part == 'ctrl') {
        modifiers.add(HotKeyModifier.control);
      } else if (part == 'shift') {
        modifiers.add(HotKeyModifier.shift);
      } else if (part == 'alt') {
        modifiers.add(HotKeyModifier.alt);
      } else if (part == 'meta' || part == 'win' || part == 'cmd') {
        modifiers.add(HotKeyModifier.meta);
      } else {
        key = _parseKey(part);
      }
    }

    if (key == LogicalKeyboardKey.f24) return null;

    return HotKey(
      key: key,
      modifiers: modifiers.isEmpty ? null : modifiers,
    );
  }

  // Chuyển chuỗi phím tắt thành nhãn hiển thị trực quan đẹp mắt
  static String getDisplayLabel(String shortcutStr) {
    if (shortcutStr.isEmpty || shortcutStr == 'None') return 'None';
    final parts = shortcutStr.split('+');
    final List<String> labels = [];
    
    for (var part in parts) {
      part = part.trim();
      final lower = part.toLowerCase();
      if (lower == 'control' || lower == 'ctrl') {
        labels.add('Ctrl');
      } else if (lower == 'shift') {
        labels.add('Shift');
      } else if (lower == 'alt') {
        labels.add('Alt');
      } else if (lower == 'meta' || lower == 'win' || lower == 'cmd') {
        labels.add('Win');
      } else {
        labels.add(_getKeyDisplayLabel(part));
      }
    }
    return labels.join(' + ');
  }

  static LogicalKeyboardKey _parseKey(String keyStr) {
    final lower = keyStr.toLowerCase();
    switch (lower) {
      case 'arrow down':
      case 'arrowdown':
        return LogicalKeyboardKey.arrowDown;
      case 'arrow up':
      case 'arrowup':
        return LogicalKeyboardKey.arrowUp;
      case 'arrow left':
      case 'arrowleft':
        return LogicalKeyboardKey.arrowLeft;
      case 'arrow right':
      case 'arrowright':
        return LogicalKeyboardKey.arrowRight;
      case 'space':
        return LogicalKeyboardKey.space;
      case 'enter':
        return LogicalKeyboardKey.enter;
      case 'escape':
      case 'esc':
        return LogicalKeyboardKey.escape;
      case 'comma':
      case ',':
        return LogicalKeyboardKey.comma;
      case 'period':
      case '.':
        return LogicalKeyboardKey.period;
      case 'slash':
      case '/':
        return LogicalKeyboardKey.slash;
      case 'tab':
        return LogicalKeyboardKey.tab;
      case 'backspace':
        return LogicalKeyboardKey.backspace;
      case 'delete':
      case 'del':
        return LogicalKeyboardKey.delete;
      
      // Phím chữ cái từ a-z
      case 'a': return LogicalKeyboardKey.keyA;
      case 'b': return LogicalKeyboardKey.keyB;
      case 'c': return LogicalKeyboardKey.keyC;
      case 'd': return LogicalKeyboardKey.keyD;
      case 'e': return LogicalKeyboardKey.keyE;
      case 'f': return LogicalKeyboardKey.keyF;
      case 'g': return LogicalKeyboardKey.keyG;
      case 'h': return LogicalKeyboardKey.keyH;
      case 'i': return LogicalKeyboardKey.keyI;
      case 'j': return LogicalKeyboardKey.keyJ;
      case 'k': return LogicalKeyboardKey.keyK;
      case 'l': return LogicalKeyboardKey.keyL;
      case 'm': return LogicalKeyboardKey.keyM;
      case 'n': return LogicalKeyboardKey.keyN;
      case 'o': return LogicalKeyboardKey.keyO;
      case 'p': return LogicalKeyboardKey.keyP;
      case 'q': return LogicalKeyboardKey.keyQ;
      case 'r': return LogicalKeyboardKey.keyR;
      case 's': return LogicalKeyboardKey.keyS;
      case 't': return LogicalKeyboardKey.keyT;
      case 'u': return LogicalKeyboardKey.keyU;
      case 'v': return LogicalKeyboardKey.keyV;
      case 'w': return LogicalKeyboardKey.keyW;
      case 'x': return LogicalKeyboardKey.keyX;
      case 'y': return LogicalKeyboardKey.keyY;
      case 'z': return LogicalKeyboardKey.keyZ;

      // Phím số từ 0-9
      case '0': return LogicalKeyboardKey.digit0;
      case '1': return LogicalKeyboardKey.digit1;
      case '2': return LogicalKeyboardKey.digit2;
      case '3': return LogicalKeyboardKey.digit3;
      case '4': return LogicalKeyboardKey.digit4;
      case '5': return LogicalKeyboardKey.digit5;
      case '6': return LogicalKeyboardKey.digit6;
      case '7': return LogicalKeyboardKey.digit7;
      case '8': return LogicalKeyboardKey.digit8;
      case '9': return LogicalKeyboardKey.digit9;

      // Phím chức năng từ F1-F12
      case 'f1': return LogicalKeyboardKey.f1;
      case 'f2': return LogicalKeyboardKey.f2;
      case 'f3': return LogicalKeyboardKey.f3;
      case 'f4': return LogicalKeyboardKey.f4;
      case 'f5': return LogicalKeyboardKey.f5;
      case 'f6': return LogicalKeyboardKey.f6;
      case 'f7': return LogicalKeyboardKey.f7;
      case 'f8': return LogicalKeyboardKey.f8;
      case 'f9': return LogicalKeyboardKey.f9;
      case 'f10': return LogicalKeyboardKey.f10;
      case 'f11': return LogicalKeyboardKey.f11;
      case 'f12': return LogicalKeyboardKey.f12;

      default:
        // Phím fallback an toàn
        return LogicalKeyboardKey.f24;
    }
  }

  static String _getKeyDisplayLabel(String keyStr) {
    final lower = keyStr.toLowerCase();
    switch (lower) {
      case 'arrow down':
      case 'arrowdown':
        return '↓';
      case 'arrow up':
      case 'arrowup':
        return '↑';
      case 'arrow left':
      case 'arrowleft':
        return '←';
      case 'arrow right':
      case 'arrowright':
        return '→';
      case 'space':
        return 'Space';
      case 'enter':
        return 'Enter';
      case 'escape':
      case 'esc':
        return 'Esc';
      case 'comma':
      case ',':
        return ',';
      case 'period':
      case '.':
        return '.';
      case 'slash':
      case '/':
        return '/';
      case 'tab':
        return 'Tab';
      case 'backspace':
        return 'Backspace';
      case 'delete':
      case 'del':
        return 'Del';
      default:
        if (keyStr.length == 1) {
          return keyStr.toUpperCase();
        }
        if (keyStr.isNotEmpty) {
          return keyStr[0].toUpperCase() + keyStr.substring(1);
        }
        return keyStr;
    }
  }
}

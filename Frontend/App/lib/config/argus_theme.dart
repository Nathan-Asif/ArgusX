import 'package:flutter/material.dart';

class ArgusTheme {
  ArgusTheme._();

  static final ValueNotifier<String> accentThemeNotifier = ValueNotifier<String>('VIOLET');

  static String get accentTheme => accentThemeNotifier.value;

  static set accentTheme(String value) {
    accentThemeNotifier.value = value;
  }

  static Color get activeColor {
    return switch (accentTheme) {
      'CYAN' => const Color(0xFF80DEEA),
      'MONO' => const Color(0xFFE5E2E3),
      _      => const Color(0xFFDDB7FF), // VIOLET
    };
  }

  static Color get glowColor {
    return switch (accentTheme) {
      'CYAN' => const Color(0xFF00E5FF),
      'MONO' => const Color(0xFF4D4354),
      _      => const Color(0xFF8E2DE2), // VIOLET
    };
  }
}

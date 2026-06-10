/// Parses "Argus" wake-word navigation commands from speech transcripts.
class ArgusVoiceCommands {
  static const wakeWord = 'argus';

  /// Chrome's speech engine frequently mishears "Argus" — accept close variants.
  static final _wakePattern = RegExp(
    r'\b(argus|argos|argis|argas|argess|argusx|argus x|august|hargus|argerse|are gus|arcus|argoose)\b',
    caseSensitive: false,
  );

  /// Strong, intent-bearing patterns. These are safe to act on even WITHOUT
  /// the wake word (useful for testing and noisy mic conditions).
  static final _commandPatterns = [
    RegExp(r'set (?:my |the )?destination (?:to|for|as) (.+)$', caseSensitive: false),
    RegExp(r'set (?:my |the )?location (?:to|for|as) (.+)$', caseSensitive: false),
    RegExp(r'change (?:my |the )?destination (?:to|for|as) (.+)$', caseSensitive: false),
    RegExp(r'change (?:my |the )?location (?:to|for|as) (.+)$', caseSensitive: false),
    RegExp(r're-?navigate (?:to |towards )?(.+)$', caseSensitive: false),
    RegExp(r'navigate (?:to|towards) (.+)$', caseSensitive: false),
    RegExp(r'route (?:me )?(?:to|towards) (.+)$', caseSensitive: false),
    RegExp(r'take me to (.+)$', caseSensitive: false),
    RegExp(r'drive (?:me )?to (.+)$', caseSensitive: false),
    RegExp(r'go to (.+)$', caseSensitive: false),
  ];

  static bool containsWakeWord(String text) => _wakePattern.hasMatch(text.trim());

  static bool isWakeWordOnly(String text) {
    final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'[.,!?]+$'), '');
    return RegExp(r'^(hey |ok |okay )?(argus|argos|argis|argas|august|hargus|arcus)$')
        .hasMatch(normalized);
  }

  /// Matches an explicit destination command (no wake word required).
  static String? extractCommand(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    for (final pattern in _commandPatterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        final place = _cleanPlace(match.group(1)!);
        if (place.length >= 2) return place;
      }
    }
    return null;
  }

  static String? extractPlace(String text, {bool requireWakeWord = true}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final command = extractCommand(trimmed);

    if (requireWakeWord) {
      if (!containsWakeWord(trimmed)) return null;
      if (command != null) return command;
      return _extractLooseAfterWake(trimmed);
    }

    return command;
  }

  static String? _extractLooseAfterWake(String text) {
    final afterWake = text.replaceFirst(_wakePattern, '').trim();
    if (afterWake.isEmpty) return null;

    final fromCommand = extractCommand(afterWake);
    if (fromCommand != null) return fromCommand;

    final loose = RegExp(
      r'(?:destination|location|to|for)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(afterWake);
    if (loose != null) {
      final place = _cleanPlace(loose.group(1)!);
      if (place.length >= 3) return place;
    }
    return null;
  }

  static String _cleanPlace(String raw) {
    return raw
        .replaceAll(RegExp(r'[?.!]+$'), '')
        .split(RegExp(r'\bis that\b', caseSensitive: false))[0]
        .split(RegExp(r'\bor\b', caseSensitive: false))[0]
        .trim();
  }
}

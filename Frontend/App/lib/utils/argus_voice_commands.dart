/// Parses "Argus" wake-word navigation commands from speech transcripts.
class ArgusVoiceCommands {
  static const wakeWord = 'argus';

  static final _wakePattern = RegExp(r'\bargus\b', caseSensitive: false);

  static final _placePatterns = [
    RegExp(
      r'argus.*?set (?:my )?(?:the )?destination (?:to|for) (.+)$',
      caseSensitive: false,
    ),
    RegExp(
      r'argus.*?set (?:my )?(?:the )?location (?:to|for) (.+)$',
      caseSensitive: false,
    ),
    RegExp(r'argus.*?renavigate (?:to )?(.+)$', caseSensitive: false),
    RegExp(r'argus.*?navigate (?:to|towards) (.+)$', caseSensitive: false),
    RegExp(r'argus.*?go to (.+)$', caseSensitive: false),
    RegExp(r'argus.*?change destination (?:to|for) (.+)$', caseSensitive: false),
    RegExp(r'argus.*?route (?:me )?to (.+)$', caseSensitive: false),
    RegExp(r'set (?:my )?(?:the )?destination (?:to|for) (.+)$', caseSensitive: false),
    RegExp(r'set (?:my )?(?:the )?location (?:to|for) (.+)$', caseSensitive: false),
    RegExp(r'renavigate (?:to )?(.+)$', caseSensitive: false),
    RegExp(r'navigate (?:to|towards) (.+)$', caseSensitive: false),
    RegExp(r'change destination (?:to|for) (.+)$', caseSensitive: false),
    RegExp(r'route (?:me )?to (.+)$', caseSensitive: false),
    RegExp(r'go to (.+)$', caseSensitive: false),
    RegExp(r'take me to (.+)$', caseSensitive: false),
  ];

  static bool containsWakeWord(String text) => _wakePattern.hasMatch(text.trim());

  static bool isWakeWordOnly(String text) {
    final normalized = text.trim().toLowerCase().replaceAll(RegExp(r'[.,!?]+$'), '');
    if (normalized == wakeWord) return true;
    return RegExp(r'^(hey |ok )?argus[!.]?$').hasMatch(normalized);
  }

  static String? extractPlace(String text, {bool requireWakeWord = true}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (requireWakeWord && !containsWakeWord(trimmed)) return null;

    for (final pattern in _placePatterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        return _cleanPlace(match.group(1)!);
      }
    }

    if (requireWakeWord) {
      return _extractLooseAfterWake(trimmed);
    }
    return _extractLooseDestination(trimmed);
  }

  static String? _extractLooseAfterWake(String text) {
    final afterWake = text.replaceFirst(_wakePattern, '').trim();
    if (afterWake.isEmpty) return null;

    final fromCommand = extractPlace(afterWake, requireWakeWord: false);
    if (fromCommand != null) return fromCommand;

    return _extractLooseDestination(afterWake);
  }

  static String? _extractLooseDestination(String text) {
    final loose = RegExp(
      r'(?:destination|location|to|for)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
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

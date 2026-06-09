import 'package:flutter_tts/flutter_tts.dart';

/// Speaks turn-by-turn navigation from backend `navigation.voice_prompt`.
class NavigationVoiceService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true;

  String? _lastNavKey;
  String? _lastHazardKey;
  int _activeStepIndex = -1;
  final Set<int> _spokenMilestones = {};

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }

  void resetRoute() {
    _lastNavKey = null;
    _lastHazardKey = null;
    _activeStepIndex = -1;
    _spokenMilestones.clear();
  }

  Future<void> announceRideStart(String destination) async {
    if (!enabled) return;
    await _speak('Navigation active. Heading to $destination.');
  }

  /// Call on each WebSocket pulse with routing agent navigation payload.
  Future<void> onNavigationUpdate(
    Map<String, dynamic> navigation, {
    required int stepIndex,
    int? remainingDistanceM,
    String threatLevel = 'NORMAL',
  }) async {
    if (!enabled || navigation.isEmpty) return;

    if (stepIndex != _activeStepIndex) {
      _activeStepIndex = stepIndex;
      _spokenMilestones.clear();
      _lastNavKey = null;
    }

    final isHazard = threatLevel == 'WARNING' || threatLevel == 'CRITICAL';
    if (isHazard) {
      await _maybeSpeakHazard(navigation);
    }

    final voice = navigation['voice_prompt'] as String?;
    if (voice == null || voice.trim().isEmpty) return;

    final arrow = (navigation['arrow'] as String? ?? 'STRAIGHT').toUpperCase();
    final instruction = navigation['instruction'] as String? ?? '';
    final navKey = '$stepIndex|$arrow|$instruction';

    if (navKey != _lastNavKey) {
      _lastNavKey = navKey;
      if (!isHazard) {
        await _speak(voice);
      }
      return;
    }

    if (remainingDistanceM == null) return;
    for (final threshold in const [500, 200, 100, 50]) {
      if (remainingDistanceM <= threshold &&
          !_spokenMilestones.contains(threshold)) {
        _spokenMilestones.add(threshold);
        final short = _shortInstruction(instruction);
        await _speak('In $threshold meters, $short');
        break;
      }
    }
  }

  Future<void> _maybeSpeakHazard(Map<String, dynamic> navigation) async {
    final voice = navigation['voice_prompt'] as String?;
    if (voice == null || voice.trim().isEmpty) return;

    final hazardKey = voice.trim();
    if (hazardKey == _lastHazardKey) return;
    _lastHazardKey = hazardKey;
    await _speak(voice);
  }

  String _shortInstruction(String instruction) {
    return instruction
        .replaceFirst(RegExp(r'^In \d+ m - '), '')
        .replaceFirst(RegExp(r'^In \d+ meters, '), '')
        .trim();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }
}

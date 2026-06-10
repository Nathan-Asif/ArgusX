import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks turn-by-turn navigation from backend `navigation.voice_prompt`.
class NavigationVoiceService {
  final FlutterTts _tts = FlutterTts();
  bool enabled = true;

  String? _lastNavKey;
  String? _lastHazardKey;
  int _activeStepIndex = -1;
  final Set<int> _spokenMilestones = {};
  DateTime? _lastSpeakAt;
  static const _minSpeakGap = Duration(seconds: 12);

  Future<void> Function()? onSpeakStart;
  Future<void> Function()? onSpeakEnd;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    if (kIsWeb) {
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
    }
    _tts.setCompletionHandler(() async {
      await onSpeakEnd?.call();
    });
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
    await _speak('Navigation active. Heading to $destination.', force: true);
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

    final isCritical = threatLevel == 'CRITICAL';
    final isHazard = threatLevel == 'WARNING' || isCritical;
    if (isHazard) {
      final advisory = navigation['hazard_advisory'] as String?;
      final hazardNav = advisory != null && advisory.trim().isNotEmpty
          ? {'voice_prompt': advisory}
          : navigation;
      await _maybeSpeakHazard(hazardNav, force: isCritical);
    }

    final voice = navigation['voice_prompt'] as String?;
    if (voice == null || voice.trim().isEmpty) return;

    final arrow = (navigation['arrow'] as String? ?? 'STRAIGHT').toUpperCase();
    final instruction = _stripDistancePrefix(
      navigation['instruction'] as String? ?? '',
    );
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
        if (short.isNotEmpty) {
          await _speak('In $threshold meters, $short');
        }
        break;
      }
    }
  }

  Future<void> _maybeSpeakHazard(
    Map<String, dynamic> navigation, {
    bool force = false,
  }) async {
    final voice = navigation['voice_prompt'] as String?;
    if (voice == null || voice.trim().isEmpty) return;

    final hazardKey = voice.trim();
    if (!force && hazardKey == _lastHazardKey) return;
    _lastHazardKey = hazardKey;
    await _speak(voice, force: force);
  }

  String _stripDistancePrefix(String instruction) {
    return instruction
        .replaceFirst(RegExp(r'^In \d+ m - '), '')
        .replaceFirst(RegExp(r'^In \d+ meters, '), '')
        .trim();
  }

  String _shortInstruction(String instruction) {
    return _stripDistancePrefix(instruction);
  }

  Future<void> _speak(String text, {bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastSpeakAt != null &&
        now.difference(_lastSpeakAt!) < _minSpeakGap) {
      return;
    }
    _lastSpeakAt = now;
    await onSpeakStart?.call();
    await _tts.stop();
    await _tts.speak(text);

    // Web TTS often never fires the completion handler — always resume listening.
    final wordCount = text.split(RegExp(r'\s+')).length;
    final estMs = (wordCount * 450 + 800).clamp(1800, 9000);
    Future.delayed(Duration(milliseconds: estMs), () async {
      await onSpeakEnd?.call();
    });
  }
}

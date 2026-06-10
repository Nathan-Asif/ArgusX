import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../utils/argus_voice_commands.dart';

enum VoiceDestinationPhase {
  idle,
  listening,
  awaitingConfirmation,
  resolving,
  confirmed,
  cancelled,
  error,
}

/// Voice flow: "Argus set location for Saddar" → confirm → callback.
class VoiceDestinationService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;

  VoiceDestinationPhase phase = VoiceDestinationPhase.idle;
  String? pendingPlace;
  String statusMessage = 'Tap mic and say: Argus set location for Saddar';

  Future<void> initialize() async {
    _speechReady = await _speech.initialize();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
  }

  Future<void> dispose() async {
    await _speech.stop();
    await _tts.stop();
  }

  Future<void> speak(String text) async {
    statusMessage = text;
    await _tts.speak(text);
  }

  Future<void> startListening({
    required void Function(String place) onConfirmed,
    void Function(String message)? onStatus,
  }) async {
    if (!_speechReady) {
      phase = VoiceDestinationPhase.error;
      statusMessage = 'Speech recognition unavailable on this device.';
      onStatus?.call(statusMessage);
      return;
    }

    phase = VoiceDestinationPhase.listening;
    statusMessage = 'Listening...';
    onStatus?.call(statusMessage);

    await _speech.listen(
      onResult: (result) => _handleTranscript(
        result.recognizedWords,
        isFinal: result.finalResult,
        onConfirmed: onConfirmed,
        onStatus: onStatus,
      ),
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    if (phase == VoiceDestinationPhase.listening) {
      phase = VoiceDestinationPhase.idle;
    }
  }

  void _handleTranscript(
    String raw, {
    required bool isFinal,
    required void Function(String place) onConfirmed,
    void Function(String message)? onStatus,
  }) {
    final text = raw.trim().toLowerCase();
    if (text.isEmpty) return;

    if (phase == VoiceDestinationPhase.awaitingConfirmation) {
      if (_isAffirmative(text)) {
        phase = VoiceDestinationPhase.confirmed;
        final place = pendingPlace ?? '';
        statusMessage = 'Destination set to $place';
        onStatus?.call(statusMessage);
        onConfirmed(place);
        return;
      }
      if (_isNegative(text)) {
        phase = VoiceDestinationPhase.cancelled;
        pendingPlace = null;
        statusMessage = 'Destination cancelled.';
        onStatus?.call(statusMessage);
        speak('Destination cancelled.');
        return;
      }
    }

    if (!isFinal) return;

    final place = _extractPlace(text);
    if (place != null) {
      pendingPlace = place;
      phase = VoiceDestinationPhase.awaitingConfirmation;
      statusMessage = 'Confirm destination: $place';
      onStatus?.call(statusMessage);
      speak('Ok sir, setting the location to $place. Is that correct?');
    }
  }

  String? _extractPlace(String text) =>
      ArgusVoiceCommands.extractPlace(text, requireWakeWord: true);

  bool _isAffirmative(String text) =>
      text.contains('yes') ||
      text.contains('yeah') ||
      text.contains('correct') ||
      text.contains('confirm') ||
      text.contains('that is right') ||
      text == 'yep';

  bool _isNegative(String text) =>
      text.contains('no') || text.contains('cancel') || text.contains('wrong');
}

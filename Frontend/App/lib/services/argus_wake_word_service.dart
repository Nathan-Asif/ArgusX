import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../utils/argus_voice_commands.dart';

enum ArgusWakeWordState {
  idle,
  awaitingGesture,
  listening,
  awaitingCommand,
  processing,
  paused,
  micError,
}

/// Hands-free "Argus" wake word + navigation command during an active ride.
class ArgusWakeWordService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _active = false;
  bool _paused = false;
  bool _speechReady = false;
  bool _gesturePrimed = false;
  bool _awaitingCommand = false;
  Timer? _commandTimeout;
  Timer? _pauseSafetyTimer;
  Timer? _transcriptDebounce;
  String _lastHandledText = '';

  ArgusWakeWordState state = ArgusWakeWordState.idle;
  String statusMessage = 'Say "Argus" then your destination';
  String lastHeard = '';

  void Function(String place)? _onDestination;
  void Function(String message)? _onStatus;

  static const _commandWindow = Duration(seconds: 8);
  static const _listenDuration = Duration(minutes: 5);
  static const _pauseDuration = Duration(seconds: 4);
  static const _webDebounce = Duration(milliseconds: 750);

  bool get isActive => _active;
  bool get isGesturePrimed => _gesturePrimed;

  String get _speechLocale => kIsWeb ? 'en-US' : 'en_US';

  Future<void> initialize() async {
    if (_speechReady) return;

    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!_active || _paused) return;
        if (status == 'done' ||
            status == 'notListening' ||
            status == 'doneNoResult') {
          _scheduleListenRestart();
        }
        if (status == 'listening') {
          _notify();
        }
      },
      onError: (error) {
        _setState(ArgusWakeWordState.micError, 'Mic error: ${error.errorMsg}');
        _scheduleListenRestart(delay: const Duration(seconds: 2));
      },
    );
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() {
      if (_active && !_paused) {
        _scheduleListenRestart();
      }
    });
  }

  Future<void> dispose() async {
    _active = false;
    _commandTimeout?.cancel();
    _pauseSafetyTimer?.cancel();
    _transcriptDebounce?.cancel();
    await _speech.stop();
    await _tts.stop();
  }

  void bind({
    required void Function(String place) onDestination,
    void Function(String message)? onStatus,
  }) {
    _onDestination = onDestination;
    _onStatus = onStatus;
    _notify();
  }

  /// Call synchronously from a button tap — Chrome requires user activation.
  Future<void> primeFromUserGesture() async {
    await initialize();
    _active = true;
    _paused = false;
    _gesturePrimed = true;
    _lastHandledText = '';
    _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
    await _startListenSession();
  }

  /// Re-activate mic after a HUD tap (web browsers stop mic without gesture).
  Future<void> activateFromUserGesture() => primeFromUserGesture();

  Future<void> start({
    required void Function(String place) onDestination,
    void Function(String message)? onStatus,
  }) async {
    bind(onDestination: onDestination, onStatus: onStatus);

    if (!_speechReady) {
      await initialize();
    }
    if (!_speechReady) {
      state = ArgusWakeWordState.idle;
      statusMessage = kIsWeb
          ? 'Voice needs Chrome/Edge and microphone permission.'
          : 'Voice commands unavailable on this device.';
      _notify();
      return;
    }

    if (_gesturePrimed && _active) {
      _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
      if (!_speech.isListening) {
        await _startListenSession();
      }
      return;
    }

    _active = true;
    _paused = false;
    _lastHandledText = '';

    if (kIsWeb) {
      _setState(
        ArgusWakeWordState.awaitingGesture,
        'Tap the ride screen once to enable Argus voice',
      );
      return;
    }

    _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
    await _startListenSession();
  }

  void pause() {
    _paused = true;
    _commandTimeout?.cancel();
    _awaitingCommand = false;
    _speech.stop();
    _pauseSafetyTimer?.cancel();
    _pauseSafetyTimer = Timer(const Duration(seconds: 8), () {
      if (_active && _paused) {
        resume();
      }
    });
    if (_active) {
      _setState(ArgusWakeWordState.paused, 'Voice paused during Argus speech');
    }
  }

  Future<void> resume() async {
    if (!_active) return;
    _paused = false;
    _pauseSafetyTimer?.cancel();
    _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
    await _startListenSession();
  }

  Future<void> speak(String text) async {
    await _speech.stop();
    await _tts.speak(text);
  }

  void _setState(ArgusWakeWordState next, String message) {
    state = next;
    statusMessage = message;
    _notify();
  }

  void _notify() {
    _onStatus?.call(statusMessage);
  }

  void _scheduleListenRestart({Duration delay = const Duration(milliseconds: 400)}) {
    if (!_active || _paused) return;
    Future.delayed(delay, () {
      if (_active && !_paused && !_speech.isListening) {
        _startListenSession();
      }
    });
  }

  Future<void> _startListenSession() async {
    if (!_active || _paused || _speech.isListening) return;

    final started = await _speech.listen(
      onResult: _handleTranscript,
      listenOptions: stt.SpeechListenOptions(
        listenFor: _listenDuration,
        pauseFor: _pauseDuration,
        partialResults: true,
        localeId: _speechLocale,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    if (!started && _active && !_paused) {
      _setState(
        ArgusWakeWordState.micError,
        kIsWeb
            ? 'Mic blocked — tap the HUD and allow microphone in the browser.'
            : 'Microphone unavailable — check app permissions.',
      );
      _scheduleListenRestart(delay: const Duration(seconds: 3));
    } else if (_active && !_paused && state == ArgusWakeWordState.micError) {
      _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
    }
  }

  void _beginAwaitingCommand() {
    _awaitingCommand = true;
    _setState(ArgusWakeWordState.awaitingCommand, 'Argus ready — say your destination');
    _commandTimeout?.cancel();
    _commandTimeout = Timer(_commandWindow, () {
      if (_awaitingCommand) {
        _awaitingCommand = false;
        _setState(ArgusWakeWordState.listening, 'Listening for "Argus"...');
      }
    });
  }

  void _handleTranscript(SpeechRecognitionResult result) {
    if (!_active || _paused) return;

    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    lastHeard = text;
    _notify();

    if (kIsWeb) {
      _transcriptDebounce?.cancel();
      _transcriptDebounce = Timer(_webDebounce, () {
        _processTranscript(text);
      });
      return;
    }

    if (!result.finalResult) return;
    _processTranscript(text);
  }

  void _processTranscript(String text) {
    if (!_active || _paused) return;
    if (text == _lastHandledText) return;

    if (_awaitingCommand) {
      final place = ArgusVoiceCommands.extractPlace(text, requireWakeWord: false);
      if (place != null) {
        _lastHandledText = text;
        _commandTimeout?.cancel();
        _awaitingCommand = false;
        _deliverDestination(place);
      }
      return;
    }

    if (!ArgusVoiceCommands.containsWakeWord(text)) return;

    final place = ArgusVoiceCommands.extractPlace(text);
    if (place != null) {
      _lastHandledText = text;
      _deliverDestination(place);
      return;
    }

    if (ArgusVoiceCommands.isWakeWordOnly(text)) {
      _lastHandledText = text;
      _beginAwaitingCommand();
      speak('Yes?');
    }
  }

  Future<void> _deliverDestination(String place) async {
    _setState(ArgusWakeWordState.processing, 'Updating route to $place...');
    pause();
    _onDestination?.call(place);
  }
}

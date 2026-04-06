import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String? _currentLanguage;
  String? _currentVoice;
  void Function(bool)? onUpdate;

  TtsService({this.onUpdate}) {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Set up callbacks to track speaking state
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      onUpdate?.call(true);
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      onUpdate?.call(false);
    });
    
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      onUpdate?.call(false);
    });
  }

  /// Sets the TTS language and finds the highest quality voice available.
  Future<void> _ensureLanguage(Locale locale) async {
    String languageCode;
    
    // Map Flutter Locales to TTS language codes
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant' || locale.countryCode == 'TW' || locale.countryCode == 'HK') {
        languageCode = "zh-TW";
      } else {
        languageCode = "zh-CN";
      }
    } else {
      languageCode = "${locale.languageCode}-${locale.countryCode ?? 'US'}";
    }

    if (_currentLanguage != languageCode) {
      final isAvailable = await _flutterTts.isLanguageAvailable(languageCode);
      if (isAvailable as bool) {
        await _flutterTts.setLanguage(languageCode);
        _currentLanguage = languageCode;
        
        // Try to find a better (Neural/Enhanced) voice
        await _pickBestVoice(languageCode);
        print("[TtsService] Language set to: $languageCode, Voice: $_currentVoice");
      }
    }
  }

  /// Searches for high-quality voices (Neural, Enhanced, Network) on the device.
  Future<void> _pickBestVoice(String languageCode) async {
    try {
      final List<dynamic>? voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) return;

      // Filter voices for the current language
      final langVoices = voices.where((v) {
        final String? locale = v["locale"];
        return locale != null && locale.toLowerCase().contains(languageCode.toLowerCase().replaceAll('-', '_'));
      }).toList();

      if (langVoices.isEmpty) return;

      // Priority ranking for voice quality keywords
      const priorities = ["neural", "enhanced", "wavenet", "network", "high", "premium"];
      
      dynamic bestVoice;
      int bestPriority = -1;

      for (var voice in langVoices) {
        final String name = (voice["name"] ?? "").toString().toLowerCase();
        
        for (int i = 0; i < priorities.length; i++) {
          if (name.contains(priorities[i])) {
            // Lower index in priority list = higher quality
            int currentPriority = priorities.length - i; 
            if (currentPriority > bestPriority) {
              bestPriority = currentPriority;
              bestVoice = voice;
            }
          }
        }
      }

      // If no high-quality keyword found, pick an arbitrary one (or stay with default)
      if (bestVoice != null) {
        await _flutterTts.setVoice({"name": bestVoice["name"], "locale": bestVoice["locale"]});
        _currentVoice = bestVoice["name"];
      } else {
        // Fallback to the first voice in the list if none matched criteria
        await _flutterTts.setVoice({"name": langVoices.first["name"], "locale": langVoices.first["locale"]});
        _currentVoice = langVoices.first["name"];
      }
    } catch (e) {
      print("[TtsService] Error picking best voice: $e");
    }
  }

  Future<void> speak(String text, {required Locale locale}) async {
    if (text.isNotEmpty) {
      await _ensureLanguage(locale);
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  bool get isSpeaking => _isSpeaking;
}


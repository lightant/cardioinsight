import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gemini_nano_android/gemini_nano_android.dart';
import '../services/gemma_inference_service.dart';
import 'settings_provider.dart';
import 'api_key_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Duration? duration;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration?.inMilliseconds,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'])
          : null,
    );
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isInitialized;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.isInitialized = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  static const _storageKey = 'chat_history';
  final _gemmaService = GemmaInferenceService();

  @override
  ChatState build() {
    _loadMessages();
    // Only eager init if selected source is Gemma
    Future.microtask(() {
      final settings = ref.read(settingsProvider);
      if (settings.aiSource == AiSource.gemmaInApp) {
        _initializeGemma();
      }
    });

    return ChatState(messages: []);
  }

  Future<void> _initializeGemma() async {
    if (state.isInitialized) return;
    try {
      await _gemmaService.initModel();
      state = state.copyWith(isInitialized: true);
      developer.log("Gemma Model Initialized", name: 'ChatNotifier');
    } catch (e) {
      developer.log(
        "Gemma Initialization Failed: $e",
        name: 'ChatNotifier',
        error: e,
      );
    }
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final messages = jsonList.map((j) => ChatMessage.fromJson(j)).toList();
      state = state.copyWith(messages: messages);
    }
  }

  Future<void> _saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> clearMessages() async {
    state = state.copyWith(messages: []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages, isLoading: true);
    _saveMessages(updatedMessages);

    final startTime = DateTime.now();

    try {
      final settings = ref.read(settingsProvider);
      final apiKey = ref.read(apiKeyProvider);
      String responseText = "";

      if (settings.aiSource == AiSource.geminiApi) {
        if (apiKey.isEmpty) {
          responseText =
              "Gemini API key is not set. Please go to Settings to set your API key.";
        } else {
          final model = GenerativeModel(
            model: 'gemini-3-flash-preview',
            apiKey: apiKey,
          );
          final prompt = [Content.text(text)];
          final response = await model.generateContent(prompt);
          responseText = response.text ?? "No response from Gemini.";
        }
      } else if (settings.aiSource == AiSource.aiCore) {
        if (defaultTargetPlatform != TargetPlatform.android || kIsWeb) {
          responseText =
              "Local AI (AICore) is only supported on Android devices.";
        } else {
          final nano = GeminiNanoAndroid();
          final isReady = await nano.isAvailable();
          if (!isReady) {
            responseText =
                "Local AI (AICore) is not ready on this device. Please ensure Google AI Services are updated.";
          } else {
            final responses = await nano.generate(
              prompt: text,
              maxOutputTokens: 256,
            );
            responseText = responses.isNotEmpty
                ? responses.first
                : "No response from AICore.";
          }
        }
      } else if (settings.aiSource == AiSource.gemmaInApp) {
        // Ensure initialized before proceeding
        if (!state.isInitialized) {
          await _initializeGemma();
        }
        // Add a restriction to the prompt to keep responses concise
        final restrictedPrompt =
            "$text\n\n(Please keep the response concise, under 512 characters.)";
        responseText = await _gemmaService.generateResponse(restrictedPrompt);

        // Clean response: remove accidental artifacts
        responseText = responseText.trim();
        responseText = responseText.replaceFirst(RegExp(r'^[?!]+'), '').trim();
      } else {
        responseText = "Selected AI source is not supported on this platform.";
      }

      developer.log(
        "AI Response received: $responseText",
        name: 'ChatNotifier',
      );

      final endTime = DateTime.now();
      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        duration: endTime.difference(startTime),
      );

      final finalMessages = [...state.messages, aiMessage];
      state = state.copyWith(messages: finalMessages, isLoading: false);
      _saveMessages(finalMessages);
    } catch (e) {
      developer.log(
        "AI Error: ${e.toString()}",
        name: 'ChatNotifier',
        error: e,
      );
      final errorMessage = ChatMessage(
        text: "Error: ${e.toString()}",
        isUser: false,
        timestamp: DateTime.now(),
      );
      final finalMessages = [...state.messages, errorMessage];
      state = state.copyWith(messages: finalMessages, isLoading: false);
      _saveMessages(finalMessages);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

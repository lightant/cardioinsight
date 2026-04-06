// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gemini_nano_android/gemini_nano_android.dart';
import '../services/gemma_inference_service.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
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

  ChatMessage copyWith({String? text}) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      duration: duration,
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
  InferenceChat? _localChat;
  
  static const _systemPrompt = """
You are a friendly, witty, and highly engaging AI companion. Your primary goal is to have natural, enjoyable, and meaningful conversations with the user.

Follow these core rules strictly:
1. Conversational Tone: Speak casually and warmly. Avoid sounding like a stiff corporate robot, an encyclopedia, or a customer service agent. Use mild humor when appropriate.
2. Brevity is Key: Keep your responses concise and punchy. People reading on mobile phones do not want to read long essays. Keep your answers to 1-3 short paragraphs maximum unless explicitly asked for a detailed explanation.
3. Be Curious: Keep the conversation flowing naturally. Whenever it makes sense, ask a light, relevant follow-up question at the end of your response to encourage the user to keep talking.
4. Honest AI Identity: You are an AI. Do not pretend to have a physical body, real human feelings, or personal life experiences. However, you can still be deeply empathetic and supportive.
5. Empathy & Matching Energy: Listen closely to the user's mood. If they are sad or venting, be comforting and validating. If they are excited, match their enthusiasm.
6. Language Alignment: Even though these instructions are in English, you MUST reply in the exact same language the user uses to speak to you (e.g., if they speak Chinese, reply in natural Chinese).
""";

  @override
  ChatState build() {
    _loadMessages();
    Future.microtask(() {
      final settings = ref.read(settingsProvider);
      if (settings.aiSource == AiSource.gemmaInApp) {
        _initializeGemma();
      }
    });

    return ChatState(messages: []);
  }

  Future<void> _initializeGemma() async {
    if (state.isInitialized && (defaultTargetPlatform == TargetPlatform.android || _localChat != null)) return;
    try {
      final settings = ref.read(settingsProvider);
      await _gemmaService.initModel(specificPath: settings.gemmaModelPath);
      
      if (defaultTargetPlatform != TargetPlatform.android) {
        // Enable thinking for Gemma 4 models (macOS/iOS only)
        final bool isGemma4 = settings.gemmaModelPath?.toLowerCase().contains('gemma-4') ?? false;
        _localChat = await _gemmaService.createChat(isThinking: isGemma4);
      }
      
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      developer.log("Gemma Initialization Failed", error: e);
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

    // 1. Initial status update
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    final history = state.messages.take(6).toList(); // Keep it context-aware
    
    try {
      final settings = ref.read(settingsProvider);
      final apiKey = ref.read(apiKeyProvider);

      // 2. Prepare the AI message placeholder
      final aiMessagePlaceholder = ChatMessage(
        text: "",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      state = state.copyWith(
        messages: [...state.messages, aiMessagePlaceholder],
        isLoading: false,
      );

      final messageIndex = state.messages.length - 1;

      if (settings.aiSource == AiSource.geminiApi && apiKey.isNotEmpty) {
        final model = GenerativeModel(
          model: 'gemini-3-flash-preview',
          apiKey: apiKey,
          systemInstruction: Content.system(_systemPrompt),
        );
        
        // Use chat session for actual history
        final chat = model.startChat(history: history.map((m) => 
          m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)])).toList());
        
        final responseStream = chat.sendMessageStream(Content.text(text));

        await for (final chunk in responseStream) {
          if (chunk.text != null) {
            _appendMessageChunk(messageIndex, chunk.text!);
          }
        }
      } else if (settings.aiSource == AiSource.gemmaInApp) {
        if (!state.isInitialized || (defaultTargetPlatform != TargetPlatform.android && _localChat == null)) {
          await _initializeGemma();
        }
        
        if (defaultTargetPlatform == TargetPlatform.android) {
          // Android: Restore original system-prompt-prefix logic
          final fullPrompt = "$_systemPrompt\n\nUser: $text\n\nAssistant: ";
          await for (final chunk in _gemmaService.generateResponseStream(fullPrompt)) {
            _appendMessageChunk(messageIndex, chunk);
          }
        } else {
          // macOS/iOS/Non-Android: Use high-level chat API for Gemma 4
          await _localChat!.addQuery(Message.text(text: text, isUser: true));
          final responseStream = _localChat!.generateChatResponseAsync();
          await for (final response in responseStream) {
            if (response is TextResponse) {
               _appendMessageChunk(messageIndex, response.token);
            }
          }
        }
      } else if (settings.aiSource == AiSource.aiCore && defaultTargetPlatform == TargetPlatform.android) {
        final nano = GeminiNanoAndroid();
        final responses = await nano.generate(prompt: "$_systemPrompt\n\nUser: $text\n\nAssistant:", maxOutputTokens: 256);
        if (responses.isNotEmpty) {
           _appendMessageChunk(messageIndex, responses.first);
        }
      } else {
        _appendMessageChunk(messageIndex, "This AI source is not supported on your current platform or settings.");
      }

      // Finalize and persist
      _saveMessages(state.messages);
      
    } catch (e) {
      developer.log("AI Send Failed", error: e);
      _appendMessageChunk(state.messages.length - 1, "\n\nError: ${e.toString()}");
    }
  }

  void _appendMessageChunk(int index, String chunk) {
    if (index < 0 || index >= state.messages.length) return;
    
    final messages = List<ChatMessage>.from(state.messages);
    final oldMessage = messages[index];
    messages[index] = oldMessage.copyWith(text: oldMessage.text + chunk);
    state = state.copyWith(messages: messages);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);


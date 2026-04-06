// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class GemmaInferenceService {
  bool _isInitialized = false;
  InferenceModel? _model;
  String? _currentModelPath;

  /// Initializes the LiteRT-LM (Gemma) engine with GPU/NPU support.
  Future<String> initModel({String? specificPath}) async {
    try {
      if (!_isInitialized) {
        print("[GemmaInferenceService] Initializing FlutterGemma facade...");
        await FlutterGemma.initialize();
        _isInitialized = true;
      }

      String? targetPath;
      print("[GemmaInferenceService] initModel called with specificPath: $specificPath");

      // 1. Try specific path
      if (specificPath != null && specificPath.isNotEmpty) {
        if (await File(specificPath).exists()) {
          targetPath = specificPath;
        }
      }

      // 2. Auto-discovery fallback
      if (targetPath == null) {
        targetPath = await _findAnyModel();
      }

      if (targetPath == null) {
        return "INIT_FAILED: No .litertlm model file found. Please select one in Settings.";
      }

      if (_model == null || _currentModelPath != targetPath) {
        print("[GemmaInferenceService] Installing/Activating model: $targetPath");
        
        // In 0.13.0, we "install" the local file to make it active
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm, 
        ).fromFile(targetPath).install();
        
        // On macOS/Desktop, PreferredBackend.gpu will use Metal/Vulkan if available
        _model = await FlutterGemma.getActiveModel(
          preferredBackend: PreferredBackend.gpu,
          maxTokens: 4096, 
        );
        
        _currentModelPath = targetPath;
      }

      return "INITIALIZED";
    } catch (e) {
      print("[GemmaInferenceService] Init error: $e");
      return "INIT_FAILED: $e";
    }
  }

  /// Scans common platform-specific directories for models.
  Future<String?> _findAnyModel() async {
    final Set<String> searchDirs = {};

    // 1. Android standard directories
    if (defaultTargetPlatform == TargetPlatform.android) {
      searchDirs.addAll([
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
      ]);
    }

    // 2. macOS/iOS/Linux standard home directories (aggressive scan)
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        searchDirs.add('$home/Downloads');
        searchDirs.add('$home/Documents');
      }
    }

    // 3. Fallback to path_provider locations
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      searchDirs.add(docsDir.path);
      
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) searchDirs.add(downloadsDir.path);
    } catch (_) {}

    print("[GemmaInferenceService] Scanning directories: $searchDirs");

    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          final files = dir.listSync();
          for (final file in files) {
            if (file is File && file.path.toLowerCase().endsWith('.litertlm')) {
              print("[GemmaInferenceService] Auto-discovered model: ${file.path}");
              return file.path;
            }
          }
        } catch (e) {
          print("[GemmaInferenceService] Error scanning $dirPath: $e");
        }
      }
    }
    return null;
  }

  /// Generates a response stream. 
  /// For Android: Uses raw session to avoid changing existing behavior.
  /// For macOS: Uses high-level InferenceChat for Gemma 4 template & Thinking Mode.
  Stream<String> generateResponseStream(String prompt, {String? modelPath}) async* {
    if (_model == null || (modelPath != null && modelPath != _currentModelPath)) {
      final status = await initModel(specificPath: modelPath);
      if (status.startsWith("INIT_FAILED")) {
        yield "Model initialization failed: $status";
        return;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: Restore original raw session logic
      InferenceModelSession? session;
      try {
        session = await _model!.createSession();
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        await for (final chunk in session.getResponseAsync()) {
          yield chunk;
        }
      } catch (e) {
        yield "Generation error: $e";
      } finally {
        await session?.close();
      }
    } else {
      // macOS/Non-Android: Use high-level chat logic for Gemma 4
      InferenceChat? chat;
      try {
        chat = await createChat(isThinking: true);
        await chat.addQuery(Message.text(text: prompt, isUser: true));
        await for (final response in chat.generateChatResponseAsync()) {
          if (response is TextResponse) {
            yield response.token;
          }
        }
      } catch (e) {
        yield "Generation error: $e";
      }
    }
  }

  Future<InferenceChat> createChat({bool isThinking = false}) async {
    if (_model == null) {
      await initModel();
    }
    if (_model == null) {
      throw Exception("Model not initialized and auto-discovery failed.");
    }

    return _model!.createChat(
      isThinking: isThinking,
      modelType: ModelType.gemmaIt, // Default for Gemma 1.1/2/4 Instruction models
    );
  }

  Future<String> generateResponse(String prompt, {String? modelPath}) async {
    final buf = StringBuffer();
    await for (final chunk in generateResponseStream(prompt, modelPath: modelPath)) {
      buf.write(chunk);
    }
    return buf.toString().trim();
  }

  Future<void> dispose() async {
    _model = null;
    _currentModelPath = null;
  }
}


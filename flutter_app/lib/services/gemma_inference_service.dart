import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class GemmaInferenceService {
  bool _isInitialized = false;
  InferenceModel? _model;
  String? _currentModelPath;

  /// Initializes the LiteRT-LM (Gemma) engine with GPU support.
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
        
        // Get the active model with GPU preference
        _model = await FlutterGemma.getActiveModel(
          preferredBackend: PreferredBackend.gpu,
          maxTokens: 2048,
        );
        
        _currentModelPath = targetPath;
      }

      return "INITIALIZED";
    } catch (e) {
      print("[GemmaInferenceService] Init error: $e");
      return "INIT_FAILED: $e";
    }
  }

  /// Scans common Android directories for any .litertlm model files.
  Future<String?> _findAnyModel() async {
    final searchDirs = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
    ];

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      searchDirs.add(externalDir.path);
    }

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

  /// Generates a response using LiteRT-LM Session.
  Future<String> generateResponse(String prompt, {String? modelPath}) async {
    if (_model == null || (modelPath != null && modelPath != _currentModelPath)) {
      final status = await initModel(specificPath: modelPath);
      if (status.startsWith("INIT_FAILED")) {
        return "Model initialization failed: $status";
      }
    }

    InferenceModelSession? session;
    try {
      print("[GemmaInferenceService] ================== AGENT PROMPT BEGIN ==================");
      print(prompt);
      print("[GemmaInferenceService] ================== AGENT PROMPT END ====================");

      print("[GemmaInferenceService] Creating LiteRT-LM GPU Session...");

      // Create a fresh session for each response to ensure statelessness for reports
      session = await _model!.createSession();
      
      // Add the user prompt as a query chunk
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      
      // Get the response
      final String response = await session.getResponse();
      
      return response.trim();
    } catch (e) {
      print("[GemmaInferenceService] Generation error: $e");
      return "Generation error: $e";
    } finally {
      // Close the session to release GPU resources
      await session?.close();
    }
  }

  Future<void> dispose() async {
    _model = null;
    _currentModelPath = null;
  }
}

import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ffi';

class GemmaInferenceService {
  LlamaEngine? _engine;
  String? _currentModelPath;

  /// Initializes the llamadart engine with the provided path or auto-discovery.
  Future<String> initModel({String? specificPath}) async {
    try {
      String? targetPath;

      print(
        "[GemmaInferenceService] initModel called with specificPath: $specificPath",
      );

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
        return "INIT_FAILED: No .gguf model file found. Please select one in Settings.";
      }

      // Unload existing engine if path changed
      if (_engine != null && _currentModelPath != targetPath) {
        await _engine!.dispose();
        _engine = null;
      }

      if (_engine == null) {
        final file = File(targetPath);
        final size = await file.length();

        // Final sanity check: Can we read the GGUF Header?
        try {
          final raf = await file.open(mode: FileMode.read);
          final header = await raf.read(4); // Read "GGUF" magic bytes
          await raf.close();
          final magic = String.fromCharCodes(header);
          final is64Bit = (sizeOf<IntPtr>() == 8);

          print(
            "[GemmaInferenceService] File Check: Magic=$magic, Size=${(size / (1024 * 1024)).toStringAsFixed(1)} MB, 64-bit System=$is64Bit",
          );

          if (magic != "GGUF") {
            return "INIT_FAILED: The file is not a valid GGUF model.";
          }

          if (!is64Bit && size > 2 * 1024 * 1024 * 1024) {
            return "INIT_FAILED: 32-bit system cannot load >2GB model.";
          }
        } catch (e) {
          return "INIT_FAILED: File access error: $e";
        }

        print(
          "[GemmaInferenceService] Initializing LlamaEngine (0.6.x) with: $targetPath",
        );

        // Initialize the new Engine/Backend architecture
        _engine = LlamaEngine(LlamaBackend());

        // Configure logging for internal troubleshooting
        LlamaEngine.configureLogging(level: LlamaLogLevel.info);

        await _engine!.loadModel(
          targetPath,
          modelParams: const ModelParams(
            gpuLayers: 0,
            preferredBackend: GpuBackend.cpu,
            contextSize: 2048,
            numberOfThreads: 4, // Safe middle ground
            batchSize: 1, // CAN BE ONLY 1
          ),
        );
        _currentModelPath = targetPath;
      }

      return "INITIALIZED";
    } catch (e) {
      print("[GemmaInferenceService] Init error: $e");
      return "INIT_FAILED: $e";
    }
  }

  /// Scans common Android directories for any .gguf model files.
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
            if (file is File && file.path.toLowerCase().endsWith('.gguf')) {
              print(
                "[GemmaInferenceService] Auto-discovered model: ${file.path}",
              );
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

  /// Generates a response using LlamaEngine's create API.
  Future<String> generateResponse(String prompt, {String? modelPath}) async {
    if (_engine == null ||
        !_engine!.isReady ||
        (modelPath != null && modelPath != _currentModelPath)) {
      final status = await initModel(specificPath: modelPath);
      if (status.startsWith("INIT_FAILED")) {
        return "Model initialization failed: $status";
      }
    }

    try {
      print(
        "[GemmaInferenceService] ================== AGENT PROMPT BEGIN ==================",
      );
      print(prompt);
      print(
        "[GemmaInferenceService] ================== AGENT PROMPT END ====================",
      );

      print("[GemmaInferenceService] Generating response via ChatSession...");

      final StringBuffer buffer = StringBuffer();

      // Use ChatSession for superior streaming and tag handling
      final session = ChatSession(_engine!);

      // Pass content parts (text-only)
      final stream = session.create(
        [LlamaTextContent(prompt)],
        enableThinking: false,
        params: const GenerationParams(
          maxTokens: 128,
          temp: 0.7,
          // Explicitly stop on common Gemma end tokens
          stopSequences: ['<end_of_turn>', '<eos>', '<|im_end|>', '</s>'],
        ),
      );

      await for (final chunk in stream) {
        final content = chunk.choices.first.delta.content;
        if (content != null) {
          buffer.write(content);
        }
      }

      // Final cleanup: remove internal leakage after the stream is done
      final result = buffer
          .toString()
          .replaceAll(RegExp(r'<unused\d+>'), '')
          .replaceAll('<end_of_turn>', '')
          .replaceAll('<eos>', '')
          .trim();

      return result;
    } catch (e) {
      print("[GemmaInferenceService] Generation error: $e");
      return "Generation error: $e";
    }
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
  }
}

import 'package:flutter/services.dart';

class GemmaInferenceService {
  static const MethodChannel _channel = MethodChannel('com.cardioinsight.cardio_insight/gemma');

  Future<String> initModel() async {
    try {
      final String? result = await _channel.invokeMethod('initModel');
      return result ?? "UNKNOWN";
    } on PlatformException catch (e) {
      throw Exception('Failed to initialize Gemma model: ${e.message}');
    }
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final String result = await _channel.invokeMethod('generateResponse', {
        'prompt': prompt,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to generate response: ${e.message}');
    }
  }
}

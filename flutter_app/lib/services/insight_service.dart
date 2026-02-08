// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/heart_rate_record.dart';
import '../models/user_profile.dart';
import 'dart:convert';

class InsightService {
  final String apiKey;
  late final GenerativeModel _model;

  InsightService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getHealthInsights(
    UserProfile profile,
    List<HeartRateRecord> records,
  ) async {
    final prompt =
        """
      You are a health assistant. Analyze the following heart rate data for ${profile.name} 
      (Age: ${profile.dob}, Height: ${profile.height}, Weight: ${profile.weight}, Activity: ${profile.activityLevel}).
      
      Records:
      ${jsonEncode(records.take(20).toList())}
      
      Provide a concise 3-sentence summary of their heart health trend and one actionable advice.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate insights at this time.";
    } catch (e) {
      return "Error generating insights: $e";
    }
  }
}

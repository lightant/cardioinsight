// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/heart_rate_record.dart';
import '../models/user_profile.dart';

class InsightService {
  final String apiKey;
  late final GenerativeModel _model;

  InsightService(this.apiKey) {
    _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
  }

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String buildPrompt(
    UserProfile profile,
    List<HeartRateRecord> records, {
    int avgHr = 0,
    int minHr = 0,
    int peakHr = 0,
    String languageCode = 'en',
  }) {
    final age = _calculateAge(profile.dob);
    final sex = profile.sex ?? 'person';
    
    // Format records into a clean text list instead of confusing JSON
    final recordsSummary = records.take(20).map((r) {
      return "- ${r.timeRange}: Avg ${r.avgHr?.toStringAsFixed(0) ?? 'N/A'} bpm (Min ${r.minHr.toStringAsFixed(0)}, Max ${r.maxHr.toStringAsFixed(0)})";
    }).join("\n");

    return '''
Analyze the heart rate for a $age year old $sex.

Stats Summary:
- Average: $avgHr bpm
- Minimum: $minHr bpm
- Peak: $peakHr bpm

Recent Activity (Last 20 records):
$recordsSummary

Task: Provide a cardio analysis and suggestions in a structured Markdown format.
Respond in $languageCode language.

Requirements:
1. Use a clear **Title** (# 🩺 Cardio Analysis).
2. Use **Headers** (##) for "Overview", "Key Insights", "Recommendations".
3. Use **Bold** text for important numbers.
4. Use **Bullet points** for readability.
5. Use emojis for section titles.
6. Keep descriptions short and concise.
7. Highlight any abnormal readings.
''';
  }

  Future<String> getHealthInsights(
    UserProfile profile,
    List<HeartRateRecord> records, {
    int avgHr = 0,
    int minHr = 0,
    int peakHr = 0,
    String languageCode = 'en',
  }) async {
    final prompt = buildPrompt(
      profile,
      records,
      avgHr: avgHr,
      minHr: minHr,
      peakHr: peakHr,
      languageCode: languageCode,
    );

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate insights at this time.";
    } catch (e) {
      return "Error generating insights: $e";
    }
  }

  /// Streams insights for real-time UI updates
  Stream<String> getHealthInsightsStream(
    UserProfile profile,
    List<HeartRateRecord> records, {
    int avgHr = 0,
    int minHr = 0,
    int peakHr = 0,
    String languageCode = 'en',
  }) async* {
    final prompt = buildPrompt(
      profile,
      records,
      avgHr: avgHr,
      minHr: minHr,
      peakHr: peakHr,
      languageCode: languageCode,
    );

    try {
      final content = [Content.text(prompt)];
      final stream = _model.generateContentStream(content);
      await for (final chunk in stream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "Error during streaming: $e";
    }
  }
}

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

  Future<String> getHealthInsights(
    UserProfile profile,
    List<HeartRateRecord> records, {
    int avgHr = 0,
    int minHr = 0,
    int peakHr = 0,
    String languageCode = 'en',
  }) async {
    final age = _calculateAge(profile.dob);
    final sex = profile.sex ?? 'person';
    final stats = {'avg': avgHr, 'min': minHr, 'peak': peakHr};

    final prompt =
        '''
Analyze the following heart rate data for a $age year old $sex.
Profile: ${jsonEncode(profile.toJson())}
Stats: ${jsonEncode(stats)}
Recent Records (Last 20): ${jsonEncode(records.take(20).map((r) => r.toJson()).toList())}

Provide a cardio analysis and suggestions in a structured Markdown format.
Respond in $languageCode language.

Requirements:
1. Use a clear **Title** with an icon (e.g., 🩺 Cardio Analysis). Use a single # for the title.
2. Use **Headers** (##) for sections like "Overview", "Key Insights", "Recommendations".
3. Use **Bold** text for important numbers and key takeaways.
4. Use **Bullet points** for readability.
5. Use **Icons** (emoji) for section titles to make it visually appealing.
6. Keep paragraphs short and concise.
7. Highlight any abnormal readings or trends.
8. Ensure there is a blank line between headers and content.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate insights at this time.";
    } catch (e) {
      return "Error generating insights: $e";
    }
  }
}

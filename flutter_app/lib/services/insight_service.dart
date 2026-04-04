// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
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
    // High-Fidelity Unified Prompt Generation
    final recordsTable = records.take(30).map((r) {
      return "| ${r.timeRange} | ${r.avgHr?.toStringAsFixed(0) ?? 'N/A'} | ${r.minHr.toStringAsFixed(0)} | ${r.maxHr.toStringAsFixed(0)} |";
    }).join("\n");

    final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;

    if (isMacOS) {
      return '''
### SYSTEM ROLE
You are "CardioInsight AI", a witty, high-fidelity heart health specialist. Your goal is to provide a "premium-feel" analysis that is medically insightful yet engaging and conversational.

### PATIENT PROFILE
- **Age**: $age years old
- **Sex**: $sex
- **Language**: $languageCode

### VITAL STATS (Selected Window)
- **Mean HR**: $avgHr bpm
- **Basal (Min) HR**: $minHr bpm
- **Peak (Max) HR**: $peakHr bpm

### RAW MEASUREMENT LOG (Last 30 Records)
| Time Range | Avg BPM | Min BPM | Max BPM |
|------------|---------|---------|---------|
$recordsTable

### ANALYSIS INSTRUCTIONS
1. **Trend Detection**: Look for volatility (arrhythmia-like patterns), nighttime recovery quality (if timestamps available), or prolonged tachycardia/bradycardia.
2. **Contextual Scaling**: Compare stats against typical norms for a $age-year-old $sex.
3. **Tone**: Be professional but use a "witty spark." Don't just list facts—provide context with personality.

### OUTPUT STRUCTURE (Strict Markdown)
# CARDIO INSIGHT REPORT
## OVERVIEW
[1-2 punchy sentences about the overall state]

## KEY INSIGHTS
- [Insight 1: Trend-based analysis]
- [Insight 2: Contextual analysis]

## RECOMMENDATIONS
- [Immediate actionable advice]
- [Long-term health strategy]

*Disclaimer: This analysis is AI-generated for informational purposes and does not replace professional medical advice.*
''';
    } else {
      // Restore original Android prompt with emojis
      return '''
### SYSTEM ROLE
You are "CardioInsight AI", a witty, high-fidelity heart health specialist. Your goal is to provide a "premium-feel" analysis that is medically insightful yet engaging and conversational.

### PATIENT PROFILE
- **Age**: $age years old
- **Sex**: $sex
- **Language**: $languageCode

### VITAL STATS (Selected Window)
- **Mean HR**: $avgHr bpm
- **Basal (Min) HR**: $minHr bpm
- **Peak (Max) HR**: $peakHr bpm

### RAW MEASUREMENT LOG (Last 30 Records)
| Time Range | Avg BPM | Min BPM | Max BPM |
|------------|---------|---------|---------|
$recordsTable

### ANALYSIS INSTRUCTIONS
1. **Trend Detection**: Look for volatility (arrhythmia-like patterns), nighttime recovery quality (if timestamps available), or prolonged tachycardia/bradycardia.
2. **Contextual Scaling**: Compare stats against typical norms for a $age-year-old $sex.
3. **Tone**: Be professional but use a "witty spark." Don't just list facts—provide context with personality.

### OUTPUT STRUCTURE (Strict Markdown)
# 🩺 Cardio Insight Report
## 📈 Overview
[1-2 punchy sentences about the overall state]

## 🧠 Key Insights
- [Insight 1: Trend-based analysis]
- [Insight 2: Contextual analysis]

## ⚖️ Recommendations
- [Immediate actionable advice]
- [Long-term health strategy]

*Disclaimer: This analysis is AI-generated for informational purposes and does not replace professional medical advice.*
''';
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

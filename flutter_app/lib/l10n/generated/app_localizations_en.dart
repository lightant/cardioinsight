// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cardio Insight';

  @override
  String get home => 'Home';

  @override
  String get insights => 'Insights';

  @override
  String get import => 'Import';

  @override
  String get settings => 'Settings';

  @override
  String get welcomeBack => 'WELCOME BACK';

  @override
  String get dailyRecords => 'Daily Records';

  @override
  String get noRecordsFound => 'No records found.';

  @override
  String get clearSelection => 'Clear';

  @override
  String get avgHr => 'AVG HR';

  @override
  String get minHr => 'MIN HR';

  @override
  String get peakHr => 'PEAK';

  @override
  String get userProfile => 'User Profile';

  @override
  String get name => 'Name';

  @override
  String get dob => 'Date of Birth';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get application => 'Application';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get setApiKey => 'Set API Key';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get yourReport => 'Your Report';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get syncHealthData => 'Sync Health Data';

  @override
  String get connectHealthConnect => 'Connect with Health Connect';

  @override
  String get importDescription =>
      'Import your heart rate data from Health Connect (Samsung Health, Google Fit, etc.) to get personalized insights.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get debugLoadSample => 'DEBUG: Load Sample Data';

  @override
  String get sex => 'Sex';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get heartRateTrend => 'Heart Rate Trend';

  @override
  String get restingHr => 'RESTING';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get allTime => 'All Time';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String recordsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String get bpm => 'bpm';

  @override
  String hrZone(Object number, Object range) {
    return 'Zone $number ($range)';
  }

  @override
  String lastSync(Object time) {
    return 'Last Sync: $time';
  }

  @override
  String recordsImported(Object count) {
    return '$count records imported';
  }

  @override
  String get chat => 'Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get clear => 'Clear';

  @override
  String get aboutAndLicenses => 'About & Licenses';

  @override
  String get aboutApp => 'About Cardio Insight';

  @override
  String get appVersion => 'Cardio Insight v1.0.0 (Flutter)';

  @override
  String get aiProvider => 'AI Powered by Gemma (Google)';

  @override
  String get gemmaTerms =>
      'This application distributes and uses the Gemma 2B model.\n\nUse of the Gemma model is subject to the Gemma Terms of Use, which can be found at: https://ai.google.dev/gemma/terms\n\nBy using the AI features in this app, you agree to not use the model for any restricted purposes as defined in the Gemma Prohibited Use Policy, including but not limited to generating illegal content, malware, or providing actionable medical advice.';

  @override
  String get close => 'Close';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get english => 'English';

  @override
  String get simplifiedChinese => 'Simplified Chinese (简体中文)';

  @override
  String get traditionalChinese => 'Traditional Chinese (繁體中文)';

  @override
  String get geminiApiKey => 'Gemini API Key';

  @override
  String get usesCloudApi => 'Uses cloud API (requires key)';

  @override
  String get onDeviceAi => 'On-device AI (AICore)';

  @override
  String get inAppAi => 'In-APP AI (Gemma)';

  @override
  String get modelName => 'Model: Gemma 4 E2B';

  @override
  String get openSourceLibraries => 'Open Source Libraries';

  @override
  String get enterApiKey => 'Enter Gemini API Key';

  @override
  String get keyRequiredMessage =>
      'Please set your Gemini API Key in Settings or click below.';

  @override
  String get tapToGenerate =>
      'Tap the refresh button to generate your AI health insights.';

  @override
  String get aiSource => 'AI Source';

  @override
  String debugRecordsLoaded(Object count) {
    return 'Loaded $count debug records';
  }

  @override
  String get readyToExport => 'Ready to export.';

  @override
  String get exportFailed => 'Export failed or no data';
}


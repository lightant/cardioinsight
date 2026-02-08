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
  String get clearSelection => 'Clear Selection';

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
}

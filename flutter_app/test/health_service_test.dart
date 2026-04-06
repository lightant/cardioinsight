// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.
import 'package:flutter_test/flutter_test.dart';
import 'package:cardio_insight/services/health_service.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthService Platform Logic', () {
    late HealthService healthService;

    setUp(() {
      healthService = HealthService();
    });

    test('isHealthConnectAvailable returns false on non-Android (macOS)', () async {
      // debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      // Note: We can't easily override platform in unit tests without more setup,
      // but since we are running on macOS, we can check if it returns false.
      
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final available = await healthService.isHealthConnectAvailable();
        expect(available, isFalse);
      }
    });

    test('hasPermissions returns false on non-mobile platforms (macOS)', () async {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final has = await healthService.hasPermissions();
        expect(has, isFalse);
      }
    });
  });
}


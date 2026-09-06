import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/core/network/staging_connection_probe.dart';

void main() {
  const enabled = bool.fromEnvironment('RUN_STAGING_SMOKE');
  test(
    'staging real: salud y protección pública, sin crear datos',
    () async {
      final json =
          jsonDecode(File('config/staging.json').readAsStringSync()) as Map;
      expect(json['APP_ENV'], 'staging');
      expect(json['DEMO_MODE'], 'false');
      final config = AppConfig.current;
      expect(
        config.environment,
        AppEnvironment.staging,
        reason: 'Usa --dart-define-from-file=config/staging.json.',
      );
      expect(config.demoMode, isFalse);
      expect(config.apiBaseUrl, json['API_BASE_URL']);
      expect(config.contentBaseUrl, json['CONTENT_BASE_URL']);
      final dio = StagingConnectionProbe.createClient(config);
      addTearDown(() => dio.close(force: true));
      final report = await StagingConnectionProbe(dio).check();
      for (final check in report.checks) {
        expect(
          check.passed,
          isTrue,
          reason: '${check.label}: ${check.message}',
        );
      }
      expect(report.passed, isTrue);
    },
    skip: enabled
        ? false
        : 'Opt-in: --dart-define=RUN_STAGING_SMOKE=true. Solo GET.',
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

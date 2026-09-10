import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android excludes private offline data from automatic backup/transfer',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:fullBackupContent="false"'));
      expect(manifest, contains('@xml/data_extraction_rules'));
      final rules = File(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ).readAsStringSync();
      for (final section in ['cloud-backup', 'device-transfer']) {
        final content = RegExp(
          '<$section>([\\s\\S]*?)</$section>',
        ).firstMatch(rules)?.group(1);
        expect(content, isNotNull);
        for (final domain in [
          'root',
          'file',
          'database',
          'sharedpref',
          'external',
          'device_root',
          'device_file',
          'device_database',
          'device_sharedpref',
        ]) {
          expect(content, contains('<exclude domain="$domain" path="." />'));
        }
      }
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../domain/account_privacy_request.dart';
import '../domain/personal_return_eligibility.dart';
import 'account_privacy_page.dart';
import 'personal_return_page.dart';

@Preview(name: 'Privacidad · teléfono', group: 'LIC-4', size: Size(375, 812))
Widget accountPrivacyPreview() => MaterialApp(
  home: AccountPrivacyBoard(
    userId: 'preview-only',
    load: (_) async => const AccountPrivacyPage(1, false, []),
    submit: (_, _) async => throw StateError('Preview does not send requests'),
  ),
);

@Preview(
  name: 'Cuenta gestionada · oscuro',
  group: 'LIC-4',
  size: Size(375, 812),
  brightness: Brightness.dark,
  textScaleFactor: 2,
)
Widget managedReturnPreview() => MaterialApp(
  theme: ThemeData(brightness: Brightness.dark),
  home: PersonalReturnBoard(
    load: () async => PersonalReturnEligibility.fromJson({
      'puedeVolver': false,
      'gestionada': true,
      'asignacionId': null,
      'versionAsignacion': null,
    }),
    submit: (_, _) async => throw StateError('Preview does not send requests'),
    refreshSession: () async => false,
  ),
);

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Scoped presentation tokens for the approved home, without retheming other flows.
abstract final class HomeDesign {
  static const primary = SaberPlusColors.primary;
  static const canvas = Color(0xFFF5F8FE);
  static const soft = Color(0xFFEAF2FF);
  static const text = Color(0xFF17243D);
  static const muted = Color(0xFF54647D);
  static const radius = 20.0;

  static bool dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color hero(BuildContext context) =>
      dark(context) ? const Color(0xFF1B2C47) : soft;
  static Color foreground(BuildContext context) =>
      dark(context) ? const Color(0xFFEEF4FF) : text;
  static Color secondaryText(BuildContext context) =>
      dark(context) ? const Color(0xFFBCC9DD) : muted;
  static Color action(BuildContext context) =>
      dark(context) ? const Color(0xFF91B8FF) : primary;
}

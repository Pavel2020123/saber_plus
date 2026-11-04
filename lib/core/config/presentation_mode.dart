import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation menu selection only, never an authentication or API permission.
/// The normal app keeps its full catalogue; main_demo opts in explicitly.
final presentationModeProvider = Provider<bool>((ref) => false);

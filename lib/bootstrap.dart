import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/environment.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current.validate();
  runApp(const ProviderScope(child: SaberPlusApp()));
}

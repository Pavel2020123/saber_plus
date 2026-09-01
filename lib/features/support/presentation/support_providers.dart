import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_support_repository.dart';
import '../data/remote_support_repository.dart';
import '../domain/support_configuration.dart';
import '../domain/support_repository.dart';

typedef SupportLinkOpener = Future<bool> Function(Uri uri);

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoSupportRepository();
  return RemoteSupportRepository(ref.watch(publicDioProvider));
});

final supportConfigurationProvider =
    FutureProvider.autoDispose<SupportConfiguration>(
      (ref) => ref.watch(supportRepositoryProvider).load(),
    );

final supportLinkOpenerProvider = Provider<SupportLinkOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

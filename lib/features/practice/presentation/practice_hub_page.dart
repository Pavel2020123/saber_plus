import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/presentation_mode.dart';
import 'practice_folders.dart';
import '../../auth/presentation/institutional_access_notice.dart';
import '../../auth/presentation/session_controller.dart';

class PracticeHubPage extends ConsumerWidget {
  const PracticeHubPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Practicar'),
      actions: [
        IconButton(
          key: const Key('open-practice-search'),
          tooltip: 'Buscar preguntas por tema',
          onPressed: () => context.go('/student/study/search'),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
    ),
    body: PracticeFolders(
      header:
          ref.watch(sessionControllerProvider).user?.institutionalAccess == null
          ? null
          : const InstitutionalAccessNotice(),
      presentation: ref.watch(presentationModeProvider),
      onOpen: (action) {
        if (action.replaceBranch) {
          context.go(action.path);
        } else {
          context.push(action.path);
        }
      },
    ),
  );
}

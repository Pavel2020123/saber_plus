import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/sync_providers.dart';
import '../../auth/presentation/session_controller.dart';
import '../../exam_countdown/presentation/exam_countdown_banner.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _synchronize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _synchronize();
  }

  void _synchronize() {
    if (!mounted) return;
    ref
        .read(sessionControllerProvider.notifier)
        .revalidateInstitutionalAccess();
    ref.read(safeSyncControllerProvider.notifier).synchronize();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.navigationShell,
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExamCountdownBanner(),
        StudentNavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) => widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          ),
        ),
      ],
    ),
  );
}

class StudentNavigationBar extends StatelessWidget {
  const StudentNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    // Keep the active name readable without adjacent labels colliding. Hidden
    // labels retain NavigationDestination semantics and tooltips.
    labelBehavior: MediaQuery.textScalerOf(context).scale(14) > 16.1
        ? NavigationDestinationLabelBehavior.onlyShowSelected
        : NavigationDestinationLabelBehavior.alwaysShow,
    destinations: const [
      NavigationDestination(
        icon: Icon(LucideIcons.house),
        selectedIcon: Icon(LucideIcons.house),
        label: 'Inicio',
      ),
      NavigationDestination(
        icon: Icon(LucideIcons.bookOpenText),
        selectedIcon: Icon(LucideIcons.bookOpenText),
        label: 'Estudiar',
      ),
      NavigationDestination(
        icon: Icon(LucideIcons.gamepad2),
        selectedIcon: Icon(LucideIcons.gamepad2),
        label: 'Practicar',
      ),
      NavigationDestination(
        icon: Icon(LucideIcons.chartArea),
        selectedIcon: Icon(LucideIcons.chartArea),
        label: 'Progreso',
      ),
      NavigationDestination(icon: Icon(LucideIcons.menu), label: 'Más'),
    ],
  );
}

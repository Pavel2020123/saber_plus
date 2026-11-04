import 'dart:ui';
import 'package:flutter/material.dart';
import '../../academic/domain/academic_models.dart';

class PracticeAction {
  const PracticeAction(
    this.id,
    this.title,
    this.icon,
    this.path, {
    this.replaceBranch = false,
  });
  final String id, title, path;
  final IconData icon;
  final bool replaceBranch;
}

class PracticeFolder {
  const PracticeFolder(this.id, this.title, this.description, this.actions);
  final String id, title, description;
  final List<PracticeAction> actions;
}

List<PracticeFolder> practiceFolders({bool presentation = false}) => [
  const PracticeFolder(
    'priorities',
    'Mis prioridades',
    'Lo que tu profesor prepara para ti',
    [
      PracticeAction(
        'open-teacher-priorities',
        'Prioridades de mi profesor',
        Icons.flag_outlined,
        '/student/practice/priorities',
      ),
    ],
  ),
  const PracticeFolder(
    'simulations',
    'Simulacros',
    'Entrena con distintos formatos de prueba',
    [
      PracticeAction(
        'open-official-simulation',
        'Simulacro 150 · AM/PM',
        Icons.fact_check_outlined,
        '/student/practice/official',
      ),
      PracticeAction(
        'open-area-simulation',
        'Simulacro por área',
        Icons.assignment_outlined,
        '/student/practice/simulation',
      ),
      PracticeAction(
        'open-historical-simulations',
        'Simulacros por año',
        Icons.inventory_2_outlined,
        '/student/practice/past',
      ),
      PracticeAction(
        'open-time-trial',
        'Prueba contrarreloj',
        Icons.bolt_rounded,
        '/student/practice/time-trial',
      ),
    ],
  ),
  PracticeFolder(
    'practice',
    'Práctica',
    'Preguntas aleatorias o por área y subtema',
    [
      const PracticeAction(
        'open-random-practice',
        'Preguntas aleatorias',
        Icons.shuffle_rounded,
        '/student/practice/random',
      ),
      for (final area in AcademicArea.values)
        PracticeAction(
          'practice-area-${area.slug}',
          area.label,
          _areaIcon(area),
          '/student/study/${area.slug}',
          replaceBranch: true,
        ),
    ],
  ),
  PracticeFolder('games', 'Juegos', 'Aprende jugando a tu ritmo', [
    const PracticeAction(
      'open-summit',
      'Salto a la cima',
      Icons.landscape_outlined,
      '/student/practice/summit',
    ),
    const PracticeAction(
      'open-star-rescue',
      'Rescate de estrellas',
      Icons.auto_awesome_outlined,
      '/student/practice/star-rescue',
    ),
    const PracticeAction(
      'open-guardian',
      'Desafío del guardián',
      Icons.shield_outlined,
      '/student/practice/guardian',
    ),
    if (!presentation) ...[
      const PracticeAction(
        'open-trivia-rush',
        'Trivia Rush',
        Icons.rocket_launch_rounded,
        '/student/practice/trivia-rush',
      ),
      const PracticeAction(
        'open-ghost-duel',
        'Duelo fantasma',
        Icons.sports_martial_arts_rounded,
        '/student/practice/ghost-duel',
      ),
      const PracticeAction(
        'open-tug-of-war',
        'Tira y afloja',
        Icons.sports_kabaddi_rounded,
        '/student/practice/tug-of-war',
      ),
    ],
  ]),
  if (!presentation)
    const PracticeFolder(
      'challenges',
      'Retos',
      'Compite con otros estudiantes',
      [
        PracticeAction(
          'open-async-battles',
          'Batallas asíncronas',
          Icons.sports_esports_outlined,
          '/student/practice/battles',
        ),
      ],
    ),
  const PracticeFolder(
    'results',
    'Mis resultados',
    'Revisa tus intentos y aprende de los errores',
    [
      PracticeAction(
        'open-practice-history',
        'Ver historial',
        Icons.history_rounded,
        '/student/practice/history',
      ),
      PracticeAction(
        'open-daily-mistakes',
        'Repasar errores de hoy',
        Icons.fact_check_outlined,
        '/student/practice/daily-review',
      ),
    ],
  ),
];
IconData _areaIcon(AcademicArea area) => switch (area) {
  AcademicArea.criticalReading => Icons.menu_book_rounded,
  AcademicArea.mathematics => Icons.calculate_rounded,
  AcademicArea.naturalSciences => Icons.science_rounded,
  AcademicArea.socialSciences => Icons.public_rounded,
  AcademicArea.english => Icons.translate_rounded,
};

class PracticeFolders extends StatefulWidget {
  const PracticeFolders({
    super.key,
    required this.onOpen,
    this.presentation = false,
    this.header,
  });
  final ValueChanged<PracticeAction> onOpen;
  final bool presentation;
  final Widget? header;
  @override
  State<PracticeFolders> createState() => _PracticeFoldersState();
}

class _PracticeFoldersState extends State<PracticeFolders> {
  bool _opening = false;
  Future<void> _open(PracticeFolder folder) async {
    if (_opening) return;
    _opening = true;
    try {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final selected = await showGeneralDialog<PracticeAction>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar carpeta',
        barrierColor: Colors.black.withValues(alpha: .35),
        transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 240),
        pageBuilder: (context, animation, secondary) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: PracticeFolderDialog(folder: folder),
        ),
        transitionBuilder: (context, animation, secondary, child) =>
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(
                    begin: .86,
                    end: 1,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              ),
            ),
      );
      if (mounted && selected != null) widget.onOpen(selected);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: SingleChildScrollView(
          key: const Key('practice-folders-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.header != null) ...[
                widget.header!,
                const SizedBox(height: 16),
              ],
              Text(
                '¿Qué quieres practicar hoy?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Toca una carpeta para descubrir sus opciones.'),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  final width =
                      (constraints.maxWidth - 20 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 24,
                    children: [
                      for (final folder in practiceFolders(
                        presentation: widget.presentation,
                      ))
                        SizedBox(
                          width: width,
                          child: _FolderTile(
                            folder: folder,
                            onTap: () => _open(folder),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onTap});
  final PracticeFolder folder;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${folder.title}, ${folder.actions.length} opciones',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('practice-folder-${folder.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: .6),
                      ),
                    ),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < 9; i++)
                          i < folder.actions.length
                              ? _ActionIcon(
                                  icon: folder.actions[i].icon,
                                  index: i,
                                  small: true,
                                )
                              : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  folder.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.index,
    this.small = false,
  });
  final IconData icon;
  final int index;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pairs = [
      (colors.primaryContainer, colors.onPrimaryContainer),
      (colors.secondaryContainer, colors.onSecondaryContainer),
      (colors.tertiaryContainer, colors.onTertiaryContainer),
    ];
    final pair = pairs[index % pairs.length];
    return Container(
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(small ? 9 : 20),
      ),
      child: Center(
        child: Icon(icon, color: pair.$2, size: small ? 19 : 32),
      ),
    );
  }
}

class PracticeFolderDialog extends StatelessWidget {
  const PracticeFolderDialog({super.key, required this.folder});
  final PracticeFolder folder;
  @override
  Widget build(BuildContext context) => Dialog(
    key: Key('practice-folder-dialog-${folder.id}'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    folder.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  key: const Key('close-practice-folder'),
                  tooltip: 'Cerrar carpeta',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              folder.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(1) > 1.4;
                    final columns = constraints.maxWidth >= 380 && !largeText
                        ? 3
                        : 2;
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < folder.actions.length; i++)
                          SizedBox(
                            width: width,
                            child: TextButton(
                              key: Key(folder.actions[i].id),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pop(context, folder.actions[i]),
                              child: Column(
                                children: [
                                  SizedBox.square(
                                    dimension: 64,
                                    child: _ActionIcon(
                                      icon: folder.actions[i].icon,
                                      index: i,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    folder.actions[i].title,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/drift_flashcard_repository.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_providers.dart';

class FlashcardSessionPage extends ConsumerStatefulWidget {
  const FlashcardSessionPage({required this.config, super.key});

  final FlashcardSessionConfig config;

  @override
  ConsumerState<FlashcardSessionPage> createState() =>
      _FlashcardSessionPageState();
}

class _FlashcardSessionPageState extends ConsumerState<FlashcardSessionPage> {
  List<Flashcard>? _session;
  var _index = 0;
  var _revealed = false;
  var _saving = false;
  var _known = 0;
  var _again = 0;
  var _finished = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(flashcardCatalogProvider);
    final progress = ref.watch(flashcardProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión de flashcards')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _SessionMessage(
          icon: Icons.error_outline_rounded,
          title: 'No pudimos cargar las tarjetas.',
        ),
        data: (cards) => progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _SessionMessage(
            icon: Icons.error_outline_rounded,
            title: 'No pudimos cargar tu progreso.',
          ),
          data: (savedProgress) {
            _session ??= buildFlashcardSession(
              cards: cards,
              progress: {for (final item in savedProgress) item.cardId: item},
              config: widget.config,
            );
            final session = _session!;
            if (session.isEmpty) {
              return const _SessionMessage(
                icon: Icons.layers_clear_outlined,
                title: 'No hay tarjetas para esos filtros.',
              );
            }
            if (_finished) return _buildResult(session.length);
            return _buildSession(session);
          },
        ),
      ),
    );
  }

  Widget _buildSession(List<Flashcard> session) {
    final card = session[_index];
    final colors = Theme.of(context).colorScheme;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / session.length,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_index + 1}/${session.length}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(label: Text(card.kind.label)),
                const SizedBox(width: 8),
                Chip(label: Text(card.area.label)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Semantics(
                button: !_revealed,
                label: _revealed
                    ? 'Respuesta de la flashcard'
                    : 'Pregunta de la flashcard. Toca para mostrar la respuesta.',
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('flashcard-face'),
                    onTap: _revealed
                        ? null
                        : () => setState(() => _revealed = true),
                    child: SizedBox.expand(
                      child: AnimatedSwitcher(
                        duration: duration,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: 0.97,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: _revealed
                            ? _FlashcardBack(key: ValueKey(card.id), card: card)
                            : _FlashcardFront(
                                key: ValueKey('${card.id}-front'),
                                card: card,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_revealed)
              FilledButton.tonalIcon(
                key: const Key('reveal-flashcard'),
                onPressed: () => setState(() => _revealed = true),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Mostrar respuesta'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('review-flashcard-again'),
                      onPressed: _saving ? null : () => _rate(card, false),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Repasar'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: colors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('master-flashcard'),
                      onPressed: _saving ? null : () => _rate(card, true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Ya la sé'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(int total) => _SessionMessage(
    icon: Icons.celebration_outlined,
    title: 'Sesión completada',
    detail:
        'Dominaste $_known de $total tarjetas y marcaste $_again para repasar.',
    actions: [
      FilledButton.icon(
        key: const Key('repeat-flashcard-session'),
        onPressed: () => setState(() {
          _index = 0;
          _revealed = false;
          _known = 0;
          _again = 0;
          _finished = false;
        }),
        icon: const Icon(Icons.replay_rounded),
        label: const Text('Repetir sesión'),
      ),
      TextButton(
        key: const Key('finish-flashcard-session'),
        onPressed: () => context.pop(),
        child: const Text('Volver a flashcards'),
      ),
    ],
  );

  Future<void> _rate(Flashcard card, bool mastered) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(flashcardRepositoryProvider)
          .recordReview(
            userId: userId,
            cardId: card.id,
            mastered: mastered,
            reviewedAt: DateTime.now(),
          );
      if (!mounted) return;
      setState(() {
        if (mastered) {
          _known++;
        } else {
          _again++;
        }
        if (_index + 1 >= _session!.length) {
          _finished = true;
        } else {
          _index++;
          _revealed = false;
        }
        _saving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar esta respuesta.')),
      );
    }
  }
}

class _FlashcardFront extends StatelessWidget {
  const _FlashcardFront({required this.card, super.key});

  final Flashcard card;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          card.kind == FlashcardKind.formula
              ? Icons.functions_rounded
              : Icons.abc_rounded,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          card.front,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        Text(
          'Piensa la respuesta y toca la tarjeta para comprobarla.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}

class _FlashcardBack extends StatelessWidget {
  const _FlashcardBack({required this.card, super.key});

  final Flashcard card;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Respuesta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        SelectableText(
          card.back,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Text(card.context),
        if (card.note case final note? when note.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(note),
        ],
      ],
    ),
  );
}

class _SessionMessage extends StatelessWidget {
  const _SessionMessage({
    required this.icon,
    required this.title,
    this.detail,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (detail case final text?) ...[
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 22),
            ...actions.expand((action) => [action, const SizedBox(height: 8)]),
          ],
        ],
      ),
    ),
  );
}

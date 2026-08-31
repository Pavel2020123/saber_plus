import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../flashcards/domain/flashcard_models.dart';
import '../../../library/presentation/reference_library_providers.dart';
import '../domain/memory_match_models.dart';

class MemoryMatchPage extends ConsumerStatefulWidget {
  const MemoryMatchPage({required this.config, super.key});

  final MemoryMatchConfig config;

  @override
  ConsumerState<MemoryMatchPage> createState() => _MemoryMatchPageState();
}

class _MemoryMatchPageState extends ConsumerState<MemoryMatchPage> {
  Timer? _timer;
  List<MemoryMatchPair>? _pairs;
  List<MemoryMatchTile>? _deck;
  Object? _error;
  final Set<String> _revealedTileIds = {};
  final Set<String> _matchedPairIds = {};
  int _moves = 0;
  int _elapsedSeconds = 0;
  bool _locked = false;
  bool _finished = false;
  bool _assisted = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadBoard);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBoard() async {
    _timer?.cancel();
    try {
      final library = await ref.read(referenceLibraryRepositoryProvider).load();
      final pairs = buildMemoryMatchPairs(
        cards: buildFlashcards(library),
        config: widget.config,
      );
      if (pairs.length < widget.config.difficulty.pairCount) {
        throw StateError(
          'No hay suficientes tarjetas para esta combinación. Prueba otra área o dificultad.',
        );
      }
      if (!mounted) return;
      setState(() {
        _pairs = pairs;
        _deck = buildMemoryMatchDeck(pairs);
        _error = null;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_finished) {
          setState(() => _elapsedSeconds++);
        }
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _selectTile(MemoryMatchTile tile) async {
    if (_locked ||
        _finished ||
        _revealedTileIds.contains(tile.id) ||
        _matchedPairIds.contains(tile.pairId)) {
      return;
    }
    setState(() => _revealedTileIds.add(tile.id));
    if (_revealedTileIds.length < 2) return;

    final deck = _deck!;
    final selected = deck
        .where((item) => _revealedTileIds.contains(item.id))
        .toList(growable: false);
    if (selected.length != 2) return;
    final isMatch = selected.first.pairId == selected.last.pairId;
    setState(() {
      _moves++;
      _locked = true;
      if (isMatch) _matchedPairIds.add(selected.first.pairId);
    });

    await Future<void>.delayed(Duration(milliseconds: isMatch ? 450 : 850));
    if (!mounted) return;
    setState(() {
      _revealedTileIds.clear();
      _locked = false;
      if (_matchedPairIds.length == (_pairs?.length ?? 0)) {
        _finished = true;
        _timer?.cancel();
      }
    });
  }

  Future<void> _showHint() async {
    if (_locked || _finished) return;
    if (_revealedTileIds.isNotEmpty) {
      _message('Termina el movimiento actual antes de pedir una pista.');
      return;
    }
    final pair = _pairs?.firstWhere(
      (item) => !_matchedPairIds.contains(item.id),
    );
    if (pair == null) return;
    final hintIds = _deck!
        .where((tile) => tile.pairId == pair.id)
        .map((tile) => tile.id)
        .toSet();
    setState(() {
      _assisted = true;
      _locked = true;
      _revealedTileIds.addAll(hintIds);
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _revealedTileIds.removeAll(hintIds);
      _locked = false;
    });
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      return _MemoryErrorView(
        message: _errorMessage(error),
        onRetry: _loadBoard,
      );
    }
    if (_deck == null || _pairs == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memoria académica')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_finished) {
      return _MemoryResultView(
        pairs: _pairs!,
        moves: _moves,
        elapsedSeconds: _elapsedSeconds,
        assisted: _assisted,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memoria académica'),
          leading: IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MemoryMetric(
                              icon: Icons.timer_outlined,
                              label: formatMemoryTime(_elapsedSeconds),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MemoryMetric(
                              icon: Icons.touch_app_outlined,
                              label: '$_moves movimientos',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MemoryMetric(
                              icon: Icons.grid_view_rounded,
                              label:
                                  '${_matchedPairIds.length}/${_pairs!.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('memory-hint-button'),
                          onPressed: _locked ? null : _showHint,
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('Pista: mostrar una pareja'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'En demostración las pistas son ilimitadas. Cada pista marcará la partida como asistida.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 150,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tile = _deck![index];
                    return _MemoryTileCard(
                      key: Key('memory-tile-${tile.id}'),
                      tile: tile,
                      revealed: _revealedTileIds.contains(tile.id),
                      matched: _matchedPairIds.contains(tile.pairId),
                      onTap: () => _selectTile(tile),
                    );
                  }, childCount: _deck!.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('El tablero actual se perderá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            key: const Key('confirm-exit-memory'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }
}

class _MemoryTileCard extends StatelessWidget {
  const _MemoryTileCard({
    required this.tile,
    required this.revealed,
    required this.matched,
    required this.onTap,
    super.key,
  });

  final MemoryMatchTile tile;
  final bool revealed;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showContent = revealed || matched;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: !matched,
      label: matched
          ? 'Pareja encontrada: ${tile.text}'
          : showContent
          ? tile.text
          : 'Tarjeta oculta',
      child: AnimatedOpacity(
        opacity: matched ? 0.55 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: matched ? null : onTap,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: showContent
                  ? Padding(
                      key: ValueKey('front-${tile.id}'),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tile.isPrompt
                                ? Icons.help_outline_rounded
                                : Icons.checklist_rounded,
                            size: 22,
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Text(
                                tile.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      key: ValueKey('back-${tile.id}'),
                      child: Icon(
                        Icons.school_rounded,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryMetric extends StatelessWidget {
  const _MemoryMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, size: 19),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _MemoryResultView extends StatelessWidget {
  const _MemoryResultView({
    required this.pairs,
    required this.moves,
    required this.elapsedSeconds,
    required this.assisted,
  });

  final List<MemoryMatchPair> pairs;
  final int moves;
  final int elapsedSeconds;
  final bool assisted;

  @override
  Widget build(BuildContext context) {
    final efficiency = moves == 0
        ? 0
        : (pairs.length * 100 / moves).clamp(0, 100);
    return Scaffold(
      key: const Key('memory-result-view'),
      appBar: AppBar(title: const Text('Partida completada')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Icon(
            Icons.psychology_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            '¡Encontraste todas las parejas!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  'Tiempo',
                  formatMemoryTime(elapsedSeconds),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _ResultMetric('Movimientos', '$moves')),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetric('Eficiencia', '${efficiency.round()} %'),
              ),
            ],
          ),
          if (assisted)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Partida asistida · no contará para récords futuros',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Parejas repasadas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final pair in pairs)
            Card(
              child: ExpansionTile(
                title: Text(pair.prompt),
                subtitle: Text(pair.area.label),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${pair.answer}\n\n${pair.context}'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('replay-memory-match'),
            onPressed: () => context.go('/student/practice/memory-match'),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Jugar otra partida'),
          ),
          TextButton(
            onPressed: () => context.go('/student/practice'),
            child: const Text('Volver a practicar'),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 14),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _MemoryErrorView extends StatelessWidget {
  const _MemoryErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Memoria académica')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_off_rounded, size: 52),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    ),
  );
}

String _errorMessage(Object error) {
  if (error is StateError) return error.message.toString();
  return 'No pudimos preparar el tablero. Intenta nuevamente.';
}

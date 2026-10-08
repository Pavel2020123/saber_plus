import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../domain/competitive_ranking_models.dart';
import 'competitive_ranking_providers.dart';

class CompetitiveRankingPage extends ConsumerStatefulWidget {
  const CompetitiveRankingPage({
    super.key,
    this.initialGame = CompetitiveGame.trivia,
  });
  final CompetitiveGame initialGame;
  @override
  ConsumerState<CompetitiveRankingPage> createState() =>
      _CompetitiveRankingPageState();
}

class _CompetitiveRankingPageState
    extends ConsumerState<CompetitiveRankingPage> {
  late CompetitiveGame _game;
  late int _season;
  late TextEditingController _year;
  String? _yearError;
  CompetitiveQuery get _query => (game: _game, season: _season);
  @override
  void initState() {
    super.initState();
    _game = widget.initialGame;
    _season = suggestedCompetitiveSeason(DateTime.now());
    _year = TextEditingController(text: '$_season');
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  void _applyYear() {
    final text = _year.text;
    final value = int.tryParse(text);
    setState(() {
      if (!RegExp(r'^[1-9]\d{0,3}$').hasMatch(text) || value == null) {
        _yearError = 'Indica un año entre 1 y 9999.';
      } else {
        _yearError = null;
        _season = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(competitiveBoardProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking competitivo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar ranking competitivo',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(competitiveBoardProvider(_query)),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<CompetitiveGame>(
                    key: const Key('competitive-game'),
                    initialValue: _game,
                    decoration: const InputDecoration(labelText: 'Juego'),
                    isExpanded: true,
                    items: CompetitiveGame.values
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              '${g.label}${g.available ? '' : ' · No disponible'}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (g) {
                      if (g != null) setState(() => _game = g);
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final yearField = TextField(
                        key: const Key('competitive-year'),
                        controller: _year,
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) => _applyYear(),
                        decoration: InputDecoration(
                          labelText: 'Temporada (año)',
                          errorText: _yearError,
                        ),
                      );
                      final submit = FilledButton(
                        onPressed: _applyYear,
                        child: const Text('Consultar'),
                      );
                      if (constraints.maxWidth < 360 ||
                          MediaQuery.textScalerOf(context).scale(16) > 24) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            yearField,
                            const SizedBox(height: 12),
                            submit,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: yearField),
                          const SizedBox(width: 12),
                          submit,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        body: board.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiError
                        ? error.message
                        : 'No pudimos cargar el ranking competitivo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (error is! ApiError ||
                      !{
                        '400',
                        '401',
                        '403',
                        'demo_unavailable',
                      }.contains(error.code))
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(competitiveBoardProvider(_query)),
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              return ref
                  .refresh(competitiveBoardProvider(_query).future)
                  .then<void>((_) {})
                  .catchError((Object error, StackTrace stack) {
                    // Riverpod retains the error for board.when above. Finish the
                    // refresh gesture without a second unhandled async exception.
                  });
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Solo alias, posición y XP competitivo. Las identidades están protegidas.',
                ),
                const SizedBox(height: 16),
                if (data.state == CompetitiveRankingState.unavailable)
                  const Text(
                    'Este juego todavía no está disponible en el ranking competitivo.',
                  )
                else if (data.state == CompetitiveRankingState.empty)
                  const Text(
                    'Aún no hay participantes con XP competitivo en esta temporada.',
                  )
                else ...[
                  Text('${data.totalParticipants} participantes'),
                  Card(
                    key: const Key('competitive-my-position'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mi posición',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            data.myPosition == null
                                ? 'Todavía no tienes una posición en este juego y temporada.'
                                : '#${data.myPosition!.position} · ${data.myPosition!.alias} · ${data.myPosition!.xp} XP',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'TOP 50 · ${data.game.label} · ${data.season}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...data.entries.map(
                    (e) => Card(
                      child: ListTile(
                        leading: Text('#${e.position}'),
                        title: Text(e.alias),
                        trailing: Text('${e.xp} XP'),
                        selected: e.isCurrentUser,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

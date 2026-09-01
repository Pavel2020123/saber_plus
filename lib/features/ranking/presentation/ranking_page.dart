import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/ranking_models.dart';
import 'ranking_providers.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  RankingScope _scope = RankingScope.global;
  RankingPeriod _period = RankingPeriod.week;

  RankingQuery get _query => (scope: _scope, period: _period);

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(rankingBoardProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        actions: [
          IconButton(
            tooltip: 'Actualizar ranking',
            onPressed: () => ref.invalidate(rankingBoardProvider(_query)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _RankingError(
          message: _message(error),
          onRetry: () => ref.invalidate(rankingBoardProvider(_query)),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(rankingBoardProvider(_query).future),
          child: ListView(
            key: const Key('ranking-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SegmentedButton<RankingScope>(
                key: const Key('ranking-scope-selector'),
                segments: [
                  const ButtonSegment(
                    value: RankingScope.global,
                    label: Text('Global'),
                    icon: Icon(Icons.public_rounded),
                  ),
                  ButtonSegment(
                    value: RankingScope.institution,
                    enabled: data.institutionAvailable,
                    label: const Text('Institución'),
                    icon: const Icon(Icons.school_outlined),
                  ),
                ],
                selected: {_scope},
                onSelectionChanged: (selection) {
                  setState(() => _scope = selection.single);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                key: const Key('ranking-period-selector'),
                spacing: 8,
                children: RankingPeriod.values
                    .map(
                      (period) => ChoiceChip(
                        key: Key('ranking-period-${period.backendValue}'),
                        label: Text(period.label),
                        selected: _period == period,
                        onSelected: (_) => setState(() => _period = period),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              _PrivacyCard(board: data),
              const SizedBox(height: 16),
              if (data.myPosition case final mine?) ...[
                _MyPositionCard(entry: mine),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.scopeName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${data.totalParticipants} participantes'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Actualizado ${_formatDate(data.updatedAt)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (data.entries.isEmpty)
                const _EmptyRanking()
              else
                ...data.entries.map(_RankingEntryCard.new),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.board});

  final RankingBoard board;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('ranking-privacy-card'),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identidades protegidas',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Solo se muestran alias, posición y XP. Nunca publicamos nombres, correos, institución ni resultados académicos.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MyPositionCard extends StatelessWidget {
  const _MyPositionCard({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('ranking-my-position'),
    color: Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      leading: CircleAvatar(child: Text('#${entry.position}')),
      title: const Text('Tu posición'),
      subtitle: Text('${_formatXp(entry.xp)} XP en este período'),
      trailing: const Icon(Icons.person_rounded),
    ),
  );
}

class _RankingEntryCard extends StatelessWidget {
  const _RankingEntryCard(this.entry);

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.position) {
      1 => Icons.workspace_premium_rounded,
      2 || 3 => Icons.military_tech_rounded,
      _ => null,
    };
    return Card(
      key: Key('ranking-entry-${entry.position}-${entry.alias}'),
      color: entry.isCurrentUser
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        leading: CircleAvatar(
          child: medal == null ? Text('${entry.position}') : Icon(medal),
        ),
        title: Text(
          entry.alias,
          style: TextStyle(
            fontWeight: entry.isCurrentUser ? FontWeight.w700 : null,
          ),
        ),
        subtitle: Text('Posición ${entry.position}'),
        trailing: Text(
          '${_formatXp(entry.xp)} XP',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.leaderboard_outlined, size: 42),
          SizedBox(height: 12),
          Text('Todavía no hay XP confirmado en este período.'),
        ],
      ),
    ),
  );
}

class _RankingError extends StatelessWidget {
  const _RankingError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _formatXp(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/'
    '${value.year} ${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _message(Object error) => switch (error) {
  ApiError(:final message) => message,
  FormatException(:final message) => message,
  _ => 'No pudimos cargar el ranking. Inténtalo nuevamente.',
};

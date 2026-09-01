import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_error.dart';
import '../domain/battle_models.dart';
import '../domain/battle_repository.dart';
import 'battle_providers.dart';

class BattleDetailPage extends ConsumerStatefulWidget {
  const BattleDetailPage({required this.battleId, super.key});

  final String battleId;

  @override
  ConsumerState<BattleDetailPage> createState() => _BattleDetailPageState();
}

class _BattleDetailPageState extends ConsumerState<BattleDetailPage> {
  BattleDetail? _latest;
  String? _selectedAnswerId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(battleDetailProvider(widget.battleId));
    final latest = _latest;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de batalla'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _busy
                ? null
                : () {
                    setState(() => _latest = null);
                    ref.invalidate(battleDetailProvider(widget.battleId));
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: latest != null
          ? _content(latest)
          : remote.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _DetailError(
                message: _message(error),
                onRetry: () =>
                    ref.invalidate(battleDetailProvider(widget.battleId)),
              ),
              data: _content,
            ),
    );
  }

  Widget _content(BattleDetail detail) => Stack(
    children: [
      RefreshIndicator(
        onRefresh: () async {
          setState(() => _latest = null);
          final refreshed = await ref.refresh(
            battleDetailProvider(widget.battleId).future,
          );
          if (mounted) setState(() => _latest = refreshed);
        },
        child: ListView(
          key: const Key('battle-detail-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _BattleHeader(detail: detail),
            const SizedBox(height: 14),
            _ProgressComparison(detail: detail),
            const SizedBox(height: 18),
            ..._stateContent(detail),
            if (detail.summary.rivalAlias != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text('Seguridad', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('report-battle-rival'),
                      onPressed: _busy ? null : () => _report(detail),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Reportar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('block-battle-rival'),
                      onPressed: _busy ? null : () => _block(detail),
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Bloquear'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      if (_busy)
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0x33000000),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ],
  );

  List<Widget> _stateContent(BattleDetail detail) {
    final summary = detail.summary;
    if (summary.status == BattleStatus.searching ||
        summary.status == BattleStatus.pending) {
      return [
        _WaitingBattle(
          detail: detail,
          onCancel: _busy
              ? null
              : () => _apply(() => _repository.cancel(summary.id)),
        ),
      ];
    }
    if (summary.status == BattleStatus.cancelled ||
        summary.status == BattleStatus.expired) {
      return [_ClosedMessage(status: summary.status)];
    }
    if (summary.status == BattleStatus.finished) {
      return [_BattleResult(detail: detail)];
    }
    if (detail.startedAt == null) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(Icons.play_circle_outline_rounded, size: 46),
                const SizedBox(height: 10),
                Text(
                  'Tu rival ya está listo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Puedes comenzar ahora y regresar más tarde. El resultado se revelará cuando ambos terminen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('start-async-battle'),
                  onPressed: _busy
                      ? null
                      : () => _apply(() => _repository.start(summary.id)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Comenzar'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    final question = detail.currentQuestion;
    if (question != null) {
      return [
        _QuestionCard(
          detail: detail,
          question: question,
          selectedAnswerId: _selectedAnswerId,
          enabled: !_busy,
          onSelected: (value) => setState(() => _selectedAnswerId = value),
          onSubmit: _selectedAnswerId == null
              ? null
              : () => _answer(detail, question),
        ),
      ];
    }
    return const [_WaitingForRival()];
  }

  Future<void> _answer(BattleDetail detail, BattleQuestion question) async {
    final answerId = _selectedAnswerId;
    if (answerId == null) return;
    await _apply(
      () => _repository.answer(
        battleId: detail.summary.id,
        questionId: question.id,
        answerId: answerId,
      ),
    );
    if (mounted) setState(() => _selectedAnswerId = null);
  }

  Future<void> _apply(Future<BattleDetail> Function() operation) async {
    setState(() => _busy = true);
    try {
      final updated = await operation();
      if (!mounted) return;
      setState(() {
        _latest = updated;
        _busy = false;
      });
      ref.invalidate(battleDashboardProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(_message(error));
    }
  }

  Future<void> _block(BattleDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bloquear rival'),
        content: const Text(
          'No volverán a ser emparejados. La otra persona no recibirá una notificación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.blockRival(detail.summary.id);
      ref.invalidate(blockedRivalsProvider);
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Rival bloqueado. No volverá a aparecer en tus emparejamientos.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(_message(error));
    }
  }

  Future<void> _report(BattleDetail detail) async {
    final report =
        await showDialog<({BattleReportReason reason, String? details})>(
          context: context,
          builder: (_) => const _ReportDialog(),
        );
    if (report == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.report(
        battleId: detail.summary.id,
        reason: report.reason,
        details: report.details,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Reporte recibido. Lo revisaremos sin revelar tu identidad.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(_message(error));
    }
  }

  BattleRepository get _repository => ref.read(battleRepositoryProvider);

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BattleHeader extends StatelessWidget {
  const _BattleHeader({required this.detail});

  final BattleDetail detail;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  detail.summary.mode.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Chip(label: Text(detail.summary.status.label)),
            ],
          ),
          const SizedBox(height: 6),
          Text(detail.summary.area?.label ?? 'Todas las áreas'),
          const SizedBox(height: 6),
          const Text(
            'Tu rival aparece con alias anónimo. No hay chat ni datos personales.',
          ),
        ],
      ),
    ),
  );
}

class _ProgressComparison extends StatelessWidget {
  const _ProgressComparison({required this.detail});

  final BattleDetail detail;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ProgressCard(
          label: 'Tú',
          progress: detail.summary.ownProgress,
          own: true,
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('VS', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      Expanded(
        child: _ProgressCard(
          label: detail.summary.rivalAlias ?? 'Sin rival',
          progress: detail.summary.rivalProgress,
          own: false,
        ),
      ),
    ],
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.progress,
    required this.own,
  });

  final String label;
  final BattleProgress? progress;
  final bool own;

  @override
  Widget build(BuildContext context) {
    final value = progress;
    return Card(
      color: own ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(
              value == null ? '—' : '${value.answered}/${value.total}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              value?.correct == null
                  ? 'Aciertos ocultos'
                  : '${value!.correct} aciertos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingBattle extends StatelessWidget {
  const _WaitingBattle({required this.detail, required this.onCancel});

  final BattleDetail detail;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final code = detail.summary.invitationCode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 44),
            const SizedBox(height: 10),
            Text(
              code == null
                  ? 'Buscando un rival anónimo'
                  : 'Comparte este código',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (code != null) ...[
              SelectableText(
                code,
                key: const Key('private-battle-code'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar código'),
              ),
            ] else
              const Text(
                'Puedes salir de esta pantalla. La búsqueda dura hasta 24 horas.',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('cancel-async-battle'),
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.detail,
    required this.question,
    required this.selectedAnswerId,
    required this.enabled,
    required this.onSelected,
    required this.onSubmit,
  });

  final BattleDetail detail;
  final BattleQuestion question;
  final String? selectedAnswerId;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pregunta ${detail.summary.ownProgress.answered + 1} de ${detail.totalQuestions}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      if (question.context?.isNotEmpty == true) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(question.context!),
          ),
        ),
        const SizedBox(height: 10),
      ],
      Text(question.statement, style: Theme.of(context).textTheme.titleLarge),
      if (question.imageUrl?.isNotEmpty == true) ...[
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            question.imageUrl!,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ],
      const SizedBox(height: 14),
      RadioGroup<String>(
        groupValue: selectedAnswerId,
        onChanged: (value) {
          if (enabled && value != null) onSelected(value);
        },
        child: Column(
          children: [
            for (final option in question.options)
              Card(
                color: selectedAnswerId == option.id
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: RadioListTile<String>(
                  value: option.id,
                  enabled: enabled,
                  title: Text(option.text),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          key: const Key('submit-async-battle-answer'),
          onPressed: enabled ? onSubmit : null,
          child: const Text('Confirmar respuesta'),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'La corrección se mostrará únicamente cuando termine la batalla.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _WaitingForRival extends StatelessWidget {
  const _WaitingForRival();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.schedule_send_outlined, size: 44),
          SizedBox(height: 10),
          Text(
            'Terminaste tu parte',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Te mostraremos el resultado y las explicaciones cuando el rival también termine.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _BattleResult extends StatelessWidget {
  const _BattleResult({required this.detail});

  final BattleDetail detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                detail.summary.result == BattleResult.victory
                    ? Icons.emoji_events_rounded
                    : Icons.analytics_outlined,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.summary.result?.label ?? 'Resultado confirmado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('+${detail.summary.xpEarned} XP de batalla'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text('Revisión', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      for (var index = 0; index < detail.questions.length; index++)
        _CorrectionCard(index: index, question: detail.questions[index]),
      if (detail.badges.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('Insignias', style: Theme.of(context).textTheme.titleMedium),
        for (final badge in detail.badges)
          ListTile(
            leading: const Icon(Icons.military_tech_rounded),
            title: Text(badge.title),
            subtitle: Text(badge.description),
          ),
      ],
    ],
  );
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.index, required this.question});

  final int index;
  final BattleQuestion question;

  @override
  Widget build(BuildContext context) {
    final own = question.options
        .where((option) => option.id == question.ownAnswerId)
        .firstOrNull;
    final correct = question.options
        .where((option) => option.id == question.correctAnswerId)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  question.isCorrect == true
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: question.isCorrect == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pregunta ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.statement),
            const SizedBox(height: 8),
            Text('Tu respuesta: ${own?.text ?? 'Sin respuesta'}'),
            if (question.isCorrect != true)
              Text('Respuesta correcta: ${correct?.text ?? 'No disponible'}'),
            if (question.explanation?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(question.explanation!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClosedMessage extends StatelessWidget {
  const _ClosedMessage({required this.status});

  final BattleStatus status;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 44),
          const SizedBox(height: 10),
          Text('Batalla ${status.label.toLowerCase()}'),
          const SizedBox(height: 4),
          const Text('Puedes crear una nueva desde el panel de batallas.'),
        ],
      ),
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  BattleReportReason _reason = BattleReportReason.inappropriateConduct;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reportar rival'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BattleReportReason>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Motivo'),
            items: BattleReportReason.values
                .map(
                  (reason) => DropdownMenuItem(
                    value: reason,
                    child: Text(reason.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() => _reason = value ?? _reason),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _details,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Detalle opcional',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-report-battle-rival'),
        onPressed: () => Navigator.pop(context, (
          reason: _reason,
          details: _details.text.trim().isEmpty ? null : _details.text.trim(),
        )),
        child: const Text('Enviar reporte'),
      ),
    ],
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

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
          const SizedBox(height: 14),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _message(Object error) {
  if (error is ApiError) return error.message;
  if (error is StateError) return error.message;
  return 'No fue posible completar la acción. Intenta nuevamente.';
}

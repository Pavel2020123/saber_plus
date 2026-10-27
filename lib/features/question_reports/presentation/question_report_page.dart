import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../domain/question_report.dart';
import 'question_report_controller.dart';

/// Permanent entry to existing reports; does not require an open graded review.
/// Reporting a NEW question still belongs exclusively in its graded review.
class MyQuestionReportsShortcut extends ConsumerWidget {
  const MyQuestionReportsShortcut({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (!canReportQuestions(user)) return const SizedBox.shrink();
    return ListTile(
      key: const Key('open-question-reports'),
      leading: const Icon(Icons.report_outlined),
      title: const Text('Mis reportes de preguntas'),
      subtitle: const Text(
        'Consulta el estado de los problemas que reportaste',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MyQuestionReportsPage(actorId: user!.id),
        ),
      ),
    );
  }
}

/// Place ONLY in a graded review with supported evidence, never an active exam.
class QuestionReportButton extends ConsumerWidget {
  const QuestionReportButton({super.key, required this.questionId});
  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (!canReportQuestions(user)) return const SizedBox.shrink();
    return TextButton.icon(
      key: Key('report-question-$questionId'),
      icon: const Icon(Icons.report_outlined),
      label: const Text('Reportar un problema'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ReportQuestionPage(questionId: questionId, actorId: user!.id),
        ),
      ),
    );
  }
}

class ReportQuestionPage extends ConsumerWidget {
  const ReportQuestionPage({
    super.key,
    required this.questionId,
    required this.actorId,
  });
  final String questionId, actorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final allowed = user?.id == actorId && canReportQuestions(user);
    // Do not even read another account's draft or initiate its repository.
    if (!allowed) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('La sesión cambió. Vuelve a entrar desde la revisión.'),
          ),
        ),
      );
    }
    final draft = ref.watch(questionReportControllerProvider(questionId));
    final controller = ref.read(
      questionReportControllerProvider(questionId).notifier,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar pregunta')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Cuéntanos qué debemos revisar. No incluyas nombres, correos ni otros datos personales. No se modificará tu nota ni tu XP.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<QuestionReportReason>(
            key: const Key('report-reason'),
            initialValue: draft.reason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motivo'),
            items: [
              for (final reason in QuestionReportReason.values)
                DropdownMenuItem(value: reason, child: Text(reason.label)),
            ],
            onChanged: draft.locked
                ? null
                : (value) => controller.edit(reason: value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: ValueKey(
              'report-detail-$actorId-$questionId-${draft.reason.name}-${draft.receipt?.id}',
            ),
            initialValue: draft.detail,
            enabled: !draft.locked,
            minLines: 3,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: 'Detalle (opcional, salvo Otro problema)',
              helperText:
                  '${draft.detail.trim().runes.length} / 500 caracteres',
            ),
            onChanged: (value) => controller.edit(detail: value),
          ),
          if (draft.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Semantics(liveRegion: true, child: Text(draft.message)),
          ],
          const SizedBox(height: 16),
          if (draft.busy) const Center(child: CircularProgressIndicator()),
          if (draft.receipt == null && draft.attempt == null)
            FilledButton(
              onPressed: draft.busy ? null : () => controller.submit(),
              child: const Text('Enviar reporte'),
            ),
          if (draft.receipt == null && draft.attempt != null) ...[
            const Text(
              'El intento se conserva solo durante esta sesión. No cambies de cuenta ni reinicies la app antes de consultar el recibo.',
            ),
            OutlinedButton(
              onPressed: draft.busy
                  ? null
                  : () => controller.submit(consult: true),
              child: const Text('Consultar recibo'),
            ),
            TextButton(
              onPressed: draft.busy ? null : () => controller.submit(),
              child: const Text('Reintentar mismo envío'),
            ),
          ],
          if (draft.receipt != null)
            const Text(
              'Recibo del envío confirmado. Consulta Mis reportes para ver el estado actual; este recibo no refleja decisiones posteriores.',
            ),
          if (draft.receipt != null)
            TextButton(
              onPressed: controller.anotherReason,
              child: const Text('Reportar otro problema de esta pregunta'),
            ),
          OutlinedButton(
            onPressed: draft.busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MyQuestionReportsPage(actorId: actorId),
                    ),
                  ),
            child: const Text('Mis reportes'),
          ),
        ],
      ),
    );
  }
}

class MyQuestionReportsPage extends ConsumerStatefulWidget {
  const MyQuestionReportsPage({super.key, required this.actorId});
  final String actorId;
  @override
  ConsumerState<MyQuestionReportsPage> createState() =>
      _MyQuestionReportsState();
}

class _MyQuestionReportsState extends ConsumerState<MyQuestionReportsPage> {
  QuestionReportPage? _page;
  int _number = 1, _version = 0;
  bool _busy = false;
  String? _error;

  bool get _allowed {
    final user = ref.read(sessionControllerProvider).user;
    return user?.id == widget.actorId && canReportQuestions(user);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted || !_allowed) return;
    final version = ++_version;
    setState(() {
      _busy = true;
      _error = null;
      _page = null;
    });
    try {
      final page = await ref
          .read(questionReportRepositoryProvider)
          .own(_number);
      if (!mounted || !_allowed || version != _version) return;
      setState(() => _page = page);
    } on Object {
      if (!mounted || !_allowed || version != _version) return;
      setState(
        () => _error =
            'No pudimos consultar tus reportes. Reintenta; no se muestra una lista vacía como si fuera éxito.',
      );
    } finally {
      if (mounted && _allowed && version == _version) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    if (user?.id != widget.actorId || !canReportQuestions(user)) {
      _version++;
      _page = null;
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('La sesión cambió. Vuelve a la revisión.')),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Estado actual de tus reportes. Un mismo motivo sobre la misma pregunta no crea otro reporte ni reabre uno cerrado.',
          ),
          OutlinedButton(
            onPressed: _busy ? null : _load,
            child: const Text('Actualizar estado'),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!),
          if (_page case final page?) ...[
            if (page.items.isEmpty)
              const Text('No hay reportes en esta página.'),
            for (final report in page.items)
              Card(
                child: ListTile(
                  title: Text(report.reason.label),
                  subtitle: Text(
                    '${questionReportStates[report.status]}\n${report.detail ?? "Sin detalle"}\nPregunta: ${report.questionId}',
                  ),
                ),
              ),
            Row(
              children: [
                TextButton(
                  onPressed: _busy || _number <= 1
                      ? null
                      : () {
                          _number--;
                          _load();
                        },
                  child: const Text('Anterior'),
                ),
                Text('Página $_number'),
                TextButton(
                  onPressed: _busy || !page.hasMore || _number >= 10000
                      ? null
                      : () {
                          _number++;
                          _load();
                        },
                  child: const Text('Siguiente'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

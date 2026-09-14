import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/pomodoro_sync_worker.dart';
import '../domain/study_evolution.dart';
import '../domain/study_time_models.dart';
import 'study_evolution_providers.dart';
import 'study_time_providers.dart';

class StudyTimePage extends ConsumerStatefulWidget {
  const StudyTimePage({super.key, this.studentId});
  final String? studentId;
  @override
  ConsumerState<StudyTimePage> createState() => _StudyTimePageState();
}

class _StudyTimePageState extends ConsumerState<StudyTimePage> {
  int _days = 30;
  bool _working = false, _showLocal = false;
  String? _syncError;
  bool get _own => widget.studentId == null;
  StudyEvolutionQuery get _query => (days: _days, studentId: widget.studentId);
  @override
  void didUpdateWidget(covariant StudyTimePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _days = 30;
      _showLocal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      sessionControllerProvider.select((s) => (s.user?.id, s.user?.role)),
      (_, _) {
        setState(() {
          _working = false;
          _showLocal = false;
          _syncError = null;
          _days = 30;
        });
      },
    );
    final report = ref.watch(studyEvolutionProvider(_query));
    final demo = ref.watch(sessionControllerProvider).user?.isDemo == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(_own ? 'Tiempo estudiado' : 'Tiempo y evolución'),
        actions: [
          IconButton(
            tooltip: 'Actualizar informe',
            onPressed: () => ref.invalidate(studyEvolutionProvider(_query)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('study-time-list'),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tiempo registrado, no atención verificada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las evaluaciones usan tiempos declarados en respuestas confirmadas. Pomodoro se muestra aparte porque puede funcionar mientras respondes. No se suman como tiempo único ni demuestran dominio.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [7, 30, 90])
                  ChoiceChip(
                    key: Key('study-days-$d'),
                    label: Text('$d días'),
                    selected: d == _days,
                    onSelected: (_) => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_own && !demo) ...[
              _queue(),
              OutlinedButton.icon(
                key: const Key('show-local-study-time'),
                onPressed: () => setState(() => _showLocal = !_showLocal),
                icon: const Icon(Icons.phone_android),
                label: Text(
                  _showLocal
                      ? 'Ocultar registros locales'
                      : 'Ver registros locales conservados',
                ),
              ),
              if (_showLocal) _localRecords(),
            ],
            report.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_off_outlined),
                      const SizedBox(height: 8),
                      Text(
                        error is ApiError
                            ? error.message
                            : 'No pudimos cargar el informe. Revisa la conexión.',
                      ),
                      const Text(
                        'No se muestran datos demo ni valores anteriores para sustituir este error.',
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(studyEvolutionProvider(_query)),
                        child: const Text('Reintentar informe'),
                      ),
                    ],
                  ),
                ),
              ),
              data: _report,
            ),
          ],
        ),
      ),
    );
  }

  Widget _queue() {
    final state = ref.watch(pomodoroQueueProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sincronización de Pomodoro',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Text(
              'Solo se encolan bloques nuevos de 25 minutos. El historial antiguo queda local. Las evaluaciones ya llegan por su calificación.',
            ),
            FilledButton.icon(
              key: const Key('sync-pomodoros'),
              onPressed: _working
                  ? null
                  : () => _run(
                      () => ref.read(pomodoroSyncWorkerProvider).synchronize(),
                    ),
              icon: const Icon(Icons.sync),
              label: Text(
                _working ? 'Sincronizando…' : 'Sincronizar pendientes',
              ),
            ),
            if (_syncError != null) Text(_syncError!),
            state.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => const Text('Leyendo cola local…'),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(pomodoroQueueProvider),
                child: const Text('No se pudo leer la cola. Reintentar'),
              ),
              data: (rows) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rows.isEmpty
                        ? 'Sin bloques pendientes en esta cuenta.'
                        : '${rows.length} bloques pendientes o por revisar${rows.length == 100 ? ' (primeros 100)' : ''}.',
                  ),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.status == 'blocked' ? 'Revisar' : 'Pendiente'} · ${_dateTime(row.endedAtUtc)} · 25 min',
                          ),
                          Text(pomodoroSyncMessage(row.errorCode)),
                          if (row.status == 'blocked')
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton(
                                  key: Key('retry-pomodoro-${row.eventId}'),
                                  onPressed: _working
                                      ? null
                                      : () => _run(
                                          () => ref
                                              .read(pomodoroSyncWorkerProvider)
                                              .retry(row.eventId),
                                        ),
                                  child: const Text('Reintentar mismo bloque'),
                                ),
                                TextButton(
                                  key: Key('local-only-${row.eventId}'),
                                  onPressed: _working
                                      ? null
                                      : () => _keepLocal(row),
                                  child: const Text('Dejar solo local'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(Future<Object?> Function() operation) async {
    final owner = ref.read(sessionControllerProvider).user?.id;
    setState(() {
      _working = true;
      _syncError = null;
    });
    try {
      await operation();
      if (mounted && owner == ref.read(sessionControllerProvider).user?.id) {
        ref.invalidate(studyEvolutionProvider);
      }
    } on Object {
      if (mounted && owner == ref.read(sessionControllerProvider).user?.id) {
        setState(
          () => _syncError =
              'No se pudo completar la sincronización local. Reintenta; los registros se conservan.',
        );
      }
    } finally {
      if (mounted && owner == ref.read(sessionControllerProvider).user?.id) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _keepLocal(PomodoroSyncEntry row) async {
    final owner = ref.read(sessionControllerProvider).user?.id;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Dejar este bloque solo local?'),
        content: const Text(
          'Se retirará de los envíos pendientes, pero conservarás su registro en este dispositivo. Si ya llegó al servidor, esta acción no lo borra de allí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Conservar solo local'),
          ),
        ],
      ),
    );
    if (!mounted ||
        yes != true ||
        owner != ref.read(sessionControllerProvider).user?.id) {
      return;
    }
    await _run(
      () => ref.read(pomodoroSyncWorkerProvider).keepLocalOnly(row.eventId),
    );
  }

  Widget _localRecords() => ref
      .watch(studyTimeRecordsProvider)
      .when(
        skipLoadingOnReload: false,
        skipLoadingOnRefresh: false,
        loading: () => const Text('Leyendo registros locales…'),
        error: (_, _) =>
            const Text('No se pudieron leer los registros locales.'),
        data: (rows) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial local — no equivale a confirmado en la nube',
                ),
                Text(
                  '${rows.length} registros conservados. Se muestran los 20 más recientes; no se suman fuentes que pueden coincidir.',
                ),
                for (final row in rows.take(20))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '${row.source.label} · ${formatStudyDuration(row.durationSeconds)} · ${_dateTime(row.recordedAt.toIso8601String())}',
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
  Widget _report(StudyEvolution data) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data.isDemo)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Demostración: datos de ejemplo. No se envían al backend ni representan a un estudiante real.',
            ),
          ),
        ),
      if (data.studentName != null)
        Text(
          data.studentName!,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      Text(
        'Del ${_date(colombianStudyDay(data.since))} al ${_date(colombianStudyDay(data.until))} · hora de Colombia',
      ),
      if (data.partial)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Muestra parcial: se alcanzó el límite de respuestas. Los totales de evaluaciones no son completos; no se calculan porcentajes ni se interpretan días vacíos.',
            ),
          ),
        ),
      _metric(
        'Tiempo en evaluaciones confirmadas',
        formatStudyDuration(data.total.evaluationSeconds),
        'study-evaluation-total',
      ),
      _metric(
        'Pomodoro declarado (puede coincidir)',
        formatStudyDuration(data.total.pomodoroSeconds),
        'study-pomodoro-total',
      ),
      Text(
        '${data.total.answers} respuestas · ${data.total['sesionesEvaluacion']} sesiones · ${data.total['bloquesPomodoro']} Pomodoros',
      ),
      Text(
        '${data.total['respuestasSinTiempo']} respuestas sin tiempo válido. No se interpretan como cero segundos.',
      ),
      const SizedBox(height: 16),
      const Text(
        'Evolución por día',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const Text(
        'Los porcentajes describen respuestas de ese día; no comparan la dificultad de los bancos ni demuestran mejora por sí solos. Sin registros no significa que no estudiaste.',
      ),
      for (final day in data.evolution.reversed)
        Card(
          child: ExpansionTile(
            key: Key('study-day-${day.date}'),
            title: Text(_date(day.date)),
            subtitle: Text(
              day.state == 'MUESTRA_PARCIAL'
                  ? 'Muestra parcial'
                  : day.state == 'SIN_REGISTROS'
                  ? 'Sin registros confirmados'
                  : '${day.metrics.answers} respuestas · ${day.metrics['bloquesPomodoro']} Pomodoros',
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evaluaciones: ${formatStudyDuration(day.metrics.evaluationSeconds)}',
              ),
              Text(
                'Pomodoro declarado: ${formatStudyDuration(day.metrics.pomodoroSeconds)}',
              ),
              Text(
                'Aciertos: ${day.metrics['aciertos']} · Errores: ${day.metrics['errores']}',
              ),
              Text(
                day.percentage == null
                    ? 'Porcentaje no disponible'
                    : 'Aciertos en esta muestra: ${day.percentage}%',
              ),
              Text('Sin tiempo válido: ${day.metrics['respuestasSinTiempo']}'),
            ],
          ),
        ),
    ],
  );
  Widget _metric(String title, String value, String key) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              value,
              key: Key(key),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(String date) =>
    '${date.substring(8, 10)}/${date.substring(5, 7)}/${date.substring(0, 4)}';
String _dateTime(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Fecha inválida';
  final local = parsed.toUtc().subtract(const Duration(hours: 5));
  return '${_date(local.toIso8601String().substring(0, 10))} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} (Colombia)';
}

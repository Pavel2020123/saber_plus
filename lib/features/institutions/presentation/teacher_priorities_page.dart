import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/teacher_priority.dart';
import 'teacher_institution_providers.dart';
import 'teacher_priority_providers.dart';

final priorityManagementEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(sessionControllerProvider).user?.isDemo == true ||
      ref
              .watch(teacherInstitutionControllerProvider)
              .valueOrNull
              ?.institution
              ?.prioritiesEnabled ==
          true,
);

String priorityError(Object error) => switch (error) {
  ApiError() => error.message,
  StateError() => error.message,
  _ =>
    'No pudimos completar la solicitud. Revisa la conexión e inténtalo de nuevo.',
};
String priorityDateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class TeacherPrioritiesPage extends ConsumerStatefulWidget {
  const TeacherPrioritiesPage({super.key, this.groupId, this.priorityId});
  final String? groupId, priorityId;
  @override
  ConsumerState<TeacherPrioritiesPage> createState() =>
      _TeacherPrioritiesPageState();
}

class _TeacherPrioritiesPageState extends ConsumerState<TeacherPrioritiesPage> {
  int _page = 1;
  bool _working = false;
  CancelToken? _writeCancel;
  bool get _student => widget.groupId == null;
  bool get _report => widget.priorityId != null;
  PriorityQuery get _query => (
    view: _student
        ? PriorityView.student
        : _report
        ? PriorityView.report
        : PriorityView.teacher,
    groupId: widget.groupId,
    priorityId: widget.priorityId,
    area: null,
    page: _page,
  );
  @override
  void dispose() {
    _writeCancel?.cancel();
    super.dispose();
  }

  void _refresh() => ref.invalidate(teacherPriorityProvider);
  @override
  Widget build(BuildContext context) {
    ref.listen(
      sessionControllerProvider.select((s) => (s.user?.id, s.user?.role)),
      (_, _) {
        _writeCancel?.cancel();
        setState(() {
          _working = false;
          _page = 1;
        });
      },
    );
    final demo = ref.watch(sessionControllerProvider).user?.isDemo == true;
    final canManage = !_student && ref.watch(priorityManagementEnabledProvider);
    final state = ref.watch(teacherPriorityProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _student
              ? 'Prioridades de mi profesor'
              : _report
              ? 'Cumplimiento del grupo'
              : 'Prioridades del grupo',
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar prioridades',
            onPressed: _working ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PriorityErrorView(error: e, retry: _refresh),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (demo)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Demostración · vista previa sin anuncios. Datos de ejemplo, no se guardan en el servidor.',
                  ),
                ),
              ),
            const Text(
              'Practicar no es lo mismo que dominar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'La meta es responder cinco preguntas distintas dentro del plazo. Los aciertos y las falencias se analizan por separado. Fechas en la hora de tu dispositivo.',
            ),
            if (!_student && !_report) ...[
              const SizedBox(height: 12),
              if (!canManage)
                const Text(
                  'Crear prioridades y consultar cumplimiento requiere el plan institucional sin anuncios. Puedes consultar títulos y retirar las existentes.',
                ),
              FilledButton.icon(
                key: const Key('create-teacher-priority'),
                onPressed: !canManage || _working
                    ? null
                    : () async {
                        await context.push(
                          '/teacher/groups/${Uri.encodeComponent(widget.groupId!)}/priorities/new',
                        );
                        if (mounted) _refresh();
                      },
                icon: const Icon(Icons.add),
                label: const Text('Asignar tema o subtema'),
              ),
            ],
            if (data.priority case final p?) ...[
              const SizedBox(height: 16),
              _details(p),
              if (!data.contentAvailable)
                const Text(
                  'Hay menos de cinco preguntas publicadas disponibles. La práctica registrada se conserva.',
                ),
            ],
            if ((_report ? data.students.isEmpty : data.priorities.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _report
                      ? 'No hay estudiantes en esta página del grupo.'
                      : _student
                      ? 'No hay prioridades en esta página. Si aún no te vinculaste a un grupo, solicita el código a tu profesor.'
                      : 'No hay prioridades en esta página.',
                ),
              ),
            for (final p in data.priorities)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _details(p),
                      if (p.progress case final progress?) ...[
                        const SizedBox(height: 12),
                        Text(progress.label),
                        if (progress.applies)
                          LinearProgressIndicator(
                            value: progress.count / 5,
                            semanticsLabel:
                                'Preguntas practicadas: ${progress.count} de 5',
                          ),
                      ],
                      if (!p.contentAvailable)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Parte del contenido ya no está publicado. Puedes practicar lo disponible; si no quedan preguntas, consulta al profesor.',
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (_student)
                        FilledButton.tonalIcon(
                          key: Key('practice-priority-${p.id}'),
                          onPressed:
                              !p.active ||
                                  p.progress?.complete == true ||
                                  p.progress?.applies != true
                              ? null
                              : () async {
                                  await context.push(
                                    '/student/practice/priorities/${Uri.encodeComponent(p.id)}/play?area=${p.area.slug}',
                                  );
                                  if (mounted) _refresh();
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Practicar preguntas pendientes'),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: !canManage || _working
                                  ? null
                                  : () => context.push(
                                      '/teacher/groups/${Uri.encodeComponent(p.groupId)}/priorities/${Uri.encodeComponent(p.id)}/report',
                                    ),
                              child: const Text('Ver cumplimiento'),
                            ),
                            TextButton(
                              onPressed: _working || p.withdrawnAt != null
                                  ? null
                                  : () => _withdraw(p),
                              child: const Text('Retirar prioridad'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            for (final student in data.students)
              Card(
                child: ListTile(
                  title: Text(student.name),
                  subtitle: Text(student.progress.label),
                  leading: Icon(
                    student.progress.complete
                        ? Icons.check_circle_outline
                        : Icons.school_outlined,
                  ),
                ),
              ),
            PriorityPagination(
              page: _page,
              hasMore: data.hasMore,
              busy: _working,
              onPage: (page) => setState(() => _page = page),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(TeacherPriority p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        p.title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      Text('${p.area.label} · ${p.topicName}'),
      if (p.groupName != null) Text('Grupo: ${p.groupName}'),
      Text('${p.stateLabel} · vence ${priorityDateLabel(p.dueAt)}'),
      if (p.withdrawnAt != null)
        Text('Retirada ${priorityDateLabel(p.withdrawnAt!)}'),
    ],
  );
  Future<void> _withdraw(TeacherPriority p) async {
    final identity = ref.read(sessionControllerProvider).user?.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Retirar esta prioridad?'),
        content: Text(
          '${p.title} dejará de sumar práctica. No se borrarán las respuestas ya registradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        identity != ref.read(sessionControllerProvider).user?.id) {
      return;
    }
    setState(() => _working = true);
    final cancel = CancelToken();
    _writeCancel = cancel;
    try {
      await ref
          .read(teacherPriorityRepositoryProvider)
          .withdraw(p.groupId, p.id, cancelToken: cancel);
      if (!mounted || cancel.isCancelled) return;
      _refresh();
    } on Object catch (e) {
      if (mounted && !cancel.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${priorityError(e)} Actualiza para confirmar el estado; retirar de nuevo no duplica la operación.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && !cancel.isCancelled) setState(() => _working = false);
    }
  }
}

class CreateTeacherPriorityPage extends ConsumerStatefulWidget {
  const CreateTeacherPriorityPage({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<CreateTeacherPriorityPage> createState() =>
      _CreateTeacherPriorityPageState();
}

class _CreateTeacherPriorityPageState
    extends ConsumerState<CreateTeacherPriorityPage> {
  AcademicArea _area = AcademicArea.mathematics;
  int _page = 1, _days = 7;
  PriorityCatalogEntry? _entry;
  bool _wholeTopic = false, _working = false;
  PriorityCreation? _pending;
  Object? _error;
  CancelToken? _cancel;
  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      sessionControllerProvider.select((s) => (s.user?.id, s.user?.role)),
      (_, _) {
        _cancel?.cancel();
        setState(() {
          _pending = null;
          _entry = null;
          _error = null;
          _working = false;
        });
      },
    );
    final query = (
      view: PriorityView.catalog,
      groupId: widget.groupId,
      priorityId: null,
      area: _area,
      page: _page,
    );
    final state = ref.watch(teacherPriorityProvider(query));
    final locked = _pending != null || _working;
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar prioridad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecciona área → tema → subtema. También puedes asignar el tema completo. La meta siempre será practicar cinco preguntas distintas.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AcademicArea>(
            key: const Key('priority-area'),
            initialValue: _area,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Área'),
            items: [
              for (final a in AcademicArea.values)
                DropdownMenuItem(value: a, child: Text(a.label)),
            ],
            onChanged: locked
                ? null
                : (v) => setState(() {
                    _area = v!;
                    _page = 1;
                    _entry = null;
                  }),
          ),
          const SizedBox(height: 12),
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => PriorityErrorView(
              error: e,
              retry: () => ref.invalidate(teacherPriorityProvider(query)),
            ),
            data: (data) => Column(
              children: [
                if (data.catalog.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay subtemas en esta página. Prueba otra área o continúa si hay más páginas.',
                    ),
                  ),
                for (final e in data.catalog)
                  Card(
                    child: ListTile(
                      key: Key('priority-catalog-${e.id}'),
                      title: Text(e.name),
                      subtitle: Text(
                        '${e.topicName} · ${e.count} preguntas publicadas${e.assignable ? '' : ' · no asignable como subtema'}',
                      ),
                      leading: Icon(
                        _entry?.id == e.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      selected: _entry?.id == e.id,
                      onTap: locked ? null : () => setState(() => _entry = e),
                    ),
                  ),
                PriorityPagination(
                  page: _page,
                  hasMore: data.hasMore,
                  busy: locked,
                  onPage: (p) => setState(() {
                    _page = p;
                    _entry = null;
                  }),
                ),
              ],
            ),
          ),
          if (_entry case final entry?) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tema completo: ${entry.topicName}'),
              subtitle: const Text(
                'Si lo desactivas, solo se asignará el subtema seleccionado.',
              ),
              value: _wholeTopic,
              onChanged: locked ? null : (v) => setState(() => _wholeTopic = v),
            ),
            DropdownButtonFormField<int>(
              initialValue: _days,
              decoration: const InputDecoration(
                labelText: 'Plazo desde la confirmación',
              ),
              items: [
                for (final d in [1, 3, 7, 14, 30])
                  DropdownMenuItem(value: d, child: Text('$d días')),
              ],
              onChanged: locked ? null : (v) => setState(() => _days = v!),
            ),
            const SizedBox(height: 16),
            if (_pending != null)
              Text('Vence: ${priorityDateLabel(_pending!.dueAt)}'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${priorityError(_error!)}\nLa operación podría haberse guardado. Reintentar conserva la misma solicitud; si vuelves atrás, consulta el listado antes de crear otra.',
                ),
              ),
            FilledButton(
              key: const Key('confirm-create-priority'),
              onPressed:
                  _working ||
                      (!_wholeTopic && !entry.assignable) ||
                      state.hasError ||
                      state.isLoading
                  ? null
                  : _create,
              child: Text(
                _working
                    ? 'Guardando…'
                    : _pending == null
                    ? 'Confirmar prioridad'
                    : 'Reintentar misma solicitud',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _create() async {
    final entry = _entry!;
    _pending ??= PriorityCreation(
      groupId: widget.groupId,
      topicId: entry.topicId,
      subtopicId: _wholeTopic ? null : entry.id,
      dueAt: DateTime.now().toUtc().add(Duration(days: _days)),
    );
    final cancel = CancelToken();
    _cancel = cancel;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await ref
          .read(teacherPriorityRepositoryProvider)
          .create(_pending!, cancelToken: cancel);
      if (!mounted || cancel.isCancelled) return;
      ref.invalidate(teacherPriorityProvider);
      context.pop();
    } on Object catch (e) {
      if (mounted && !cancel.isCancelled) setState(() => _error = e);
    } finally {
      if (mounted && !cancel.isCancelled) setState(() => _working = false);
    }
  }
}

class PriorityPagination extends StatelessWidget {
  const PriorityPagination({
    super.key,
    required this.page,
    required this.hasMore,
    required this.busy,
    required this.onPage,
  });
  final int page;
  final bool hasMore, busy;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: busy || page == 1 ? null : () => onPage(page - 1),
          child: const Text('Anterior'),
        ),
        Text('Página $page'),
        TextButton(
          onPressed: busy || !hasMore || page >= 1000
              ? null
              : () => onPage(page + 1),
          child: const Text('Siguiente'),
        ),
      ],
    ),
  );
}

class PriorityErrorView extends StatelessWidget {
  const PriorityErrorView({
    super.key,
    required this.error,
    required this.retry,
  });
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(priorityError(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: const Text('Reintentar')),
          ],
        ),
      ),
    ),
  );
}

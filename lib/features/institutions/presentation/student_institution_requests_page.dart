import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/institution_directory.dart';
import '../domain/student_institution_request.dart';
import '../domain/teacher_institution_models.dart';
import '../data/student_request_notice_store.dart';
import 'student_institution_request_providers.dart';
import 'teacher_institution_providers.dart';

/// La autorización real es del servidor. Esta envoltura evita ofrecer controles
/// del propietario a un docente lector y reinicia estado al cambiar de sesión.
class StudentInstitutionRequestsPage extends ConsumerWidget {
  const StudentInstitutionRequestsPage({
    super.key,
    this.ownerInbox = false,
    this.target,
  });
  final bool ownerInbox;
  final PublicInstitution? target;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    Widget unavailable(String text) => Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de estudiantes')),
      body: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
    );
    if (user == null) {
      return unavailable('Inicia sesión para consultar tus solicitudes.');
    }
    if (user.isDemo) {
      return unavailable(
        'Las solicitudes reales requieren una cuenta de SaberPlus. No se envían desde la demostración.',
      );
    }
    if ((!ownerInbox && user.role != AppRole.student) ||
        (ownerInbox && user.role != AppRole.teacher)) {
      return unavailable('Esta cuenta no tiene acceso a esta pantalla.');
    }
    final repository = ref.watch(studentInstitutionRequestRepositoryProvider);
    Widget board() => StudentInstitutionRequestsBoard(
      key: ValueKey((user.id, repository, ownerInbox, target?.id)),
      repository: repository,
      ownerInbox: ownerInbox,
      target: target,
      linkedInstitutionId: user.institutionId,
      onRefreshMembership: () =>
          ref.read(sessionControllerProvider.notifier).refreshProfile(),
      onRequestsChanged: () => ref.invalidate(studentRequestMenuProvider),
      onRejectionViewed: ownerInbox
          ? null
          : (request) async {
              await ref
                  .read(studentRequestNoticeStoreProvider)
                  .markRead(user.id, request);
              ref.invalidate(studentRequestMenuProvider);
            },
    );
    if (!ownerInbox) return board();
    final membership = ref.watch(teacherInstitutionControllerProvider);
    return membership.when(
      skipLoadingOnRefresh: false,
      loading: () => unavailable('Consultando permisos institucionales…'),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Solicitudes de estudiantes')),
        body: Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(teacherInstitutionControllerProvider),
            child: const Text('Reintentar consulta de permisos'),
          ),
        ),
      ),
      data: (data) =>
          data.status == TeacherInstitutionStatus.linked &&
              data.memberRole == InstitutionMemberRole.owner &&
              data.institution?.verificationState == 'APROBADA'
          ? board()
          : unavailable(
              'Solo el propietario de una institución aprobada puede revisar estas solicitudes.',
            ),
    );
  }
}

class StudentInstitutionRequestsBoard extends StatefulWidget {
  const StudentInstitutionRequestsBoard({
    super.key,
    required this.repository,
    this.ownerInbox = false,
    this.target,
    this.linkedInstitutionId,
    this.onRefreshMembership,
    this.onRequestsChanged,
    this.onRejectionViewed,
  });
  final StudentInstitutionRequestRepository repository;
  final bool ownerInbox;
  final PublicInstitution? target;
  final String? linkedInstitutionId;
  final Future<void> Function()? onRefreshMembership;
  final VoidCallback? onRequestsChanged;
  final Future<void> Function(StudentInstitutionRequest)? onRejectionViewed;
  @override
  State<StudentInstitutionRequestsBoard> createState() =>
      _StudentInstitutionRequestsBoardState();
}

class _StudentInstitutionRequestsBoardState
    extends State<StudentInstitutionRequestsBoard> {
  final _text = TextEditingController();
  StudentInstitutionRequestPage? _data;
  StudentRequestStatus _filter = StudentRequestStatus.pending;
  int _page = 1;
  bool _busy = false,
      _mustConsult = false,
      _editing = false,
      _allowExit = false,
      _dialogOpen = false;
  String? _message, _operationId, _submittedMessage;
  final _viewedRejections = <String>{};
  bool get _locked => _busy || _dialogOpen;
  bool get _draft =>
      _operationId != null ||
      (_editing && _text.text.trim().isNotEmpty) ||
      _mustConsult;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) return;
    final wasUncertain = _mustConsult;
    setState(() => _busy = true);
    try {
      final data = widget.ownerInbox
          ? await widget.repository.inbox(_page, _filter)
          : await widget.repository.own(_page);
      if (!mounted) return;
      setState(() {
        _data = data;
        _mustConsult = false;
        if (wasUncertain && _operationId == null) {
          _message =
              'Estado actual consultado. Revisa el historial antes de decidir nuevamente.';
        }
        if (_operationId != null) {
          final previous = data.items.where((r) => r.id == _operationId);
          if (previous.isNotEmpty) {
            _message = 'Estado confirmado: ${previous.first.status.label}.';
            _operationId = null;
            _submittedMessage = null;
            _text.clear();
            _editing = false;
          } else {
            _message =
                'No aparece este intento en el historial consultado. Puedes reintentar el mismo envío, sin crear otro.';
          }
        }
      });
      widget.onRequestsChanged?.call();
      final latest = data.items.firstOrNull;
      if (!widget.ownerInbox &&
          _page == 1 &&
          latest?.status == StudentRequestStatus.rejected) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
          final version = '${latest!.id}:${latest.revision}';
          if (_viewedRejections.contains(version) ||
              widget.onRejectionViewed == null) {
            return;
          }
          try {
            await widget.onRejectionViewed!(latest);
            if (mounted) _viewedRejections.add(version);
          } catch (_) {
            if (mounted) {
              setState(
                () => _message =
                    'El resultado está disponible, pero no pudimos recordar su lectura en este dispositivo.',
              );
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = null;
          _mustConsult = true;
          _message =
              'No pudimos consultar las solicitudes. Conservamos cualquier borrador; reintenta la consulta.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String text, String action) async {
    if (_locked) return false;
    setState(() => _dialogOpen = true);
    try {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Volver'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(action),
                ),
              ],
            ),
          ) ==
          true;
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  Future<void> _run(Future<StudentInstitutionRequest> Function() action) async {
    if (_locked || _mustConsult) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _message = 'Estado confirmado: ${result.status.label}.';
        _editing = false;
        _text.clear();
        _operationId = null;
        _submittedMessage = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _mustConsult = true;
          _message =
              'No se pudo confirmar la operación. Consulta el estado antes de reenviarla; podría haberse guardado.';
          if (error is ApiError && ['400', '403', '409'].contains(error.code)) {
            _message = '$_message ${error.message}';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && !_mustConsult) await _load();
  }

  Future<void> _send() async {
    final target = widget.target;
    if (target == null ||
        _locked ||
        _mustConsult ||
        !_editing ||
        _text.text.trim().runes.length > 500) {
      return;
    }
    if (!await _confirm(
          '¿Solicitar ingreso?',
          'Enviarás una solicitud a ${target.name}. Su propietario decidirá si acepta tu ingreso.',
          'Enviar solicitud',
        ) ||
        !mounted) {
      return;
    }
    _operationId ??= newStudentRequestId();
    _submittedMessage ??= _text.text.trim();
    await _run(
      () => widget.repository.create(
        operationId: _operationId!,
        institutionId: target.id,
        message: _submittedMessage!,
      ),
    );
  }

  Future<void> _decide(StudentInstitutionRequest row, {bool? approve}) async {
    final title = approve == null
        ? '¿Cancelar solicitud?'
        : approve
        ? '¿Aceptar estudiante?'
        : '¿Rechazar solicitud?';
    final detail = approve == null
        ? 'La solicitud de ingreso a ${row.institutionName} quedará cancelada.'
        : approve
        ? '${row.studentName ?? 'El estudiante'} ingresará a tu institución como estudiante, sin asignación automática de grupo.'
        : 'Esta solicitud no vinculará al estudiante. Podrá consultar el resultado en su historial.';
    if (_mustConsult ||
        !await _confirm(title, detail, 'Confirmar') ||
        !mounted) {
      return;
    }
    await _run(
      () => approve == null
          ? widget.repository.cancel(row)
          : widget.repository.review(row, approve: approve),
    );
  }

  Future<void> _exit() async {
    if (!_draft ||
        !await _confirm(
          '¿Salir de solicitudes?',
          'Se descartará el borrador de esta pantalla. Si un envío no se confirmó, consulta el historial al volver: podría estar guardado.',
          'Salir',
        ) ||
        !mounted) {
      return;
    }
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final pending = data?.items
        .where((r) => r.status == StudentRequestStatus.pending)
        .firstOrNull;
    final canCompose =
        !widget.ownerInbox &&
        widget.target != null &&
        widget.linkedInstitutionId == null &&
        data != null &&
        _page == 1 &&
        pending == null;
    return PopScope(
      canPop: _allowExit || (!_draft && !_locked),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.ownerInbox
                ? 'Solicitudes de estudiantes'
                : 'Mis solicitudes de ingreso',
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.ownerInbox
                    ? 'Revisa quién solicita ingresar a tu institución.'
                    : 'Aquí puedes consultar si tu solicitud fue aceptada, rechazada o sigue pendiente.',
              ),
              const SizedBox(height: 12),
              if (_busy) const LinearProgressIndicator(),
              if (!widget.ownerInbox &&
                  data?.items.firstOrNull?.status ==
                      StudentRequestStatus.rejected)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${data!.items.first.institutionName} rechazó tu solicitud de ingreso. Puedes enviar una nueva solicitud si corresponde.',
                    ),
                  ),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_message!)),
                ),
              OutlinedButton.icon(
                onPressed: _locked ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Consultar estado actual'),
              ),
              if (widget.ownerInbox)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: DropdownButtonFormField<StudentRequestStatus>(
                    initialValue: _filter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estado de solicitudes',
                    ),
                    items: StudentRequestStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: _locked || _mustConsult
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _filter = value;
                              _page = 1;
                            });
                            _load();
                          },
                  ),
                ),
              if (!widget.ownerInbox && widget.linkedInstitutionId != null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Ya perteneces a una institución. Puedes consultar tu historial, pero no solicitar un traslado desde aquí.',
                  ),
                ),
              if (!widget.ownerInbox && pending != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Pendiente de revisión · ${pending.institutionName}. No necesitas enviar otra solicitud.',
                  ),
                ),
              if (canCompose) ...[
                const SizedBox(height: 12),
                Text(
                  'Ingreso a ${widget.target!.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!_editing)
                  OutlinedButton.icon(
                    onPressed: _locked || _mustConsult
                        ? null
                        : () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Escribir solicitud'),
                  ),
                if (_editing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('student-request-message'),
                    controller: _text,
                    readOnly: _locked || _operationId != null,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje opcional',
                      helperText:
                          'No incluyas contraseñas, documentos ni datos sensibles.',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  FilledButton(
                    onPressed:
                        _locked ||
                            _mustConsult ||
                            _text.text.trim().runes.length > 500
                        ? null
                        : _send,
                    child: Text(
                      _operationId == null
                          ? 'Solicitar ingreso'
                          : 'Reintentar mismo envío',
                    ),
                  ),
                ],
              ],
              if (data != null) ...[
                const SizedBox(height: 20),
                Text(
                  widget.ownerInbox
                      ? 'Bandeja institucional'
                      : 'Historial privado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (data.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No hay solicitudes en esta consulta.'),
                  ),
                for (final row in data.items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ownerInbox
                                ? row.studentName ?? 'Estudiante'
                                : row.institutionName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(row.status.label),
                          Text(
                            'Actualizada: ${MaterialLocalizations.of(context).formatMediumDate(row.updatedAt.toLocal())}',
                          ),
                          if (row.message?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(row.message!),
                            ),
                          if (row.status == StudentRequestStatus.pending)
                            Wrap(
                              spacing: 8,
                              children: widget.ownerInbox
                                  ? [
                                      FilledButton(
                                        onPressed: _locked || _mustConsult
                                            ? null
                                            : () => _decide(row, approve: true),
                                        child: const Text('Aceptar'),
                                      ),
                                      OutlinedButton(
                                        onPressed: _locked || _mustConsult
                                            ? null
                                            : () =>
                                                  _decide(row, approve: false),
                                        child: const Text('Rechazar'),
                                      ),
                                    ]
                                  : [
                                      TextButton(
                                        onPressed: _locked || _mustConsult
                                            ? null
                                            : () => _decide(row),
                                        child: const Text('Cancelar solicitud'),
                                      ),
                                    ],
                            ),
                          if (!widget.ownerInbox &&
                              row.status == StudentRequestStatus.approved) ...[
                            const Text(
                              'Tu ingreso fue aceptado. Puedes consultar tu institución y grupos.',
                            ),
                            if (widget.linkedInstitutionId !=
                                    row.institutionId &&
                                widget.onRefreshMembership != null)
                              TextButton(
                                onPressed: _locked
                                    ? null
                                    : () async {
                                        setState(() => _busy = true);
                                        try {
                                          await widget.onRefreshMembership!();
                                        } finally {
                                          if (mounted) {
                                            setState(() => _busy = false);
                                          }
                                        }
                                      },
                                child: const Text(
                                  'Actualizar mi vínculo institucional',
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _locked || _mustConsult || _page <= 1 || _draft
                          ? null
                          : () {
                              setState(() => _page--);
                              _load();
                            },
                      child: const Text('Anterior'),
                    ),
                    Text('Página ${data.page}'),
                    TextButton(
                      onPressed:
                          _locked ||
                              _mustConsult ||
                              !data.hasMore ||
                              _page >= 10000 ||
                              _draft
                          ? null
                          : () {
                              setState(() => _page++);
                              _load();
                            },
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

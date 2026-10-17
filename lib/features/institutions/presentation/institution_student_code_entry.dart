import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../domain/student_institution_code.dart';
import '../domain/student_institution_request.dart';
import 'institution_code_confirmation.dart';

class InstitutionStudentCodeEntry extends StatefulWidget {
  const InstitutionStudentCodeEntry({
    super.key,
    required this.repository,
    required this.consultMembership,
    required this.onJoined,
    required this.onRequests,
    this.linkedInstitutionId,
  });
  final StudentInstitutionCodeRepository repository;
  final String? linkedInstitutionId;
  final Future<String?> Function() consultMembership;
  final Future<void> Function() onJoined, onRequests;
  @override
  State<InstitutionStudentCodeEntry> createState() =>
      _InstitutionStudentCodeEntryState();
}

class _InstitutionStudentCodeEntryState
    extends State<InstitutionStudentCodeEntry> {
  final _code = TextEditingController();
  final _dialogs = InstitutionCodeConfirmation();
  InstitutionCodePreview? _preview;
  InstitutionCodeJoinAttempt? _attempt;
  InstitutionCodeJoinResult? _joined;
  bool _busy = false,
      _confirming = false,
      _mustConsult = false,
      _allowExit = false,
      _linkedElsewhere = false;
  String? _message;

  @override
  void dispose() {
    _dialogs.dispose();
    _code.dispose();
    _preview = null;
    _attempt = null;
    super.dispose();
  }

  bool get _hasLink =>
      _joined != null || widget.linkedInstitutionId != null || _linkedElsewhere;

  @override
  void didUpdateWidget(covariant InstitutionStudentCodeEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.linkedInstitutionId != widget.linkedInstitutionId) {
      _dialogs.dispose();
      _code.clear();
      _preview = null;
      _attempt = null;
      _mustConsult = false;
      _linkedElsewhere = false;
      if (_joined?.institution.id != widget.linkedInstitutionId) _joined = null;
    }
  }

  Future<void> _previewCode() async {
    if (_busy || _mustConsult || _attempt != null || _hasLink) return;
    final code = normalizeInstitutionStudentCode(_code.text);
    if (!isInstitutionStudentCode(code)) {
      setState(() {
        _preview = null;
        _message =
            'Pide al propietario el código de estudiantes: SPI- seguido de 32 letras o números. No uses el código de grupo.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _preview = null;
      _message = null;
    });
    try {
      final preview = await widget.repository.preview(code);
      if (!mounted || normalizeInstitutionStudentCode(_code.text) != code) {
        return;
      }
      setState(() => _preview = preview);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = _error(
            error,
            'No pudimos consultar ese código. Revisa la conexión y pide el vigente al propietario.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final preview = _preview;
    if (_busy ||
        _mustConsult ||
        _hasLink ||
        preview == null ||
        preview.alreadyLinked) {
      return;
    }
    setState(() {
      _busy = true;
      _confirming = _attempt == null;
    });
    try {
      if (_attempt == null) {
        final accepted = await _dialogs.show(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('¿Unirte a esta institución?'),
            content: Text(
              '${preview.institution.name}\n\nIngresarás como estudiante, sin asignación automática a un grupo. Esto no realiza traslados entre instituciones.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar ingreso'),
              ),
            ],
          ),
        );
        if (!mounted || accepted != true || _hasLink) return;
        setState(() => _confirming = false);
        _attempt = InstitutionCodeJoinAttempt(
          operationId: newStudentRequestId(),
          code: normalizeInstitutionStudentCode(_code.text),
          preview: preview,
        );
      }
      final attempt = _attempt!;
      final result = await widget.repository.join(attempt);
      if (!mounted) return;
      if (result.institution.id != attempt.preview.institution.id) {
        throw const FormatException('Institución inesperada.');
      }
      setState(() {
        _joined = result;
        _attempt = null;
        _preview = null;
        _code.clear();
        _message =
            'Ingreso confirmado. Ya perteneces a ${result.institution.name}.';
      });
      await _refreshAfterJoin();
    } catch (error) {
      if (mounted) {
        setState(() {
          _mustConsult = true;
          _message = _error(
            error,
            'No se pudo confirmar el ingreso. Consulta tu vínculo antes de reenviarlo; podría haberse guardado.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  Future<void> _refreshAfterJoin() async {
    try {
      await widget.onJoined();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'El ingreso fue confirmado, pero no pudimos actualizar el perfil. Pulsa Actualizar mi vínculo.',
        );
      }
    }
  }

  Future<void> _consult() async {
    if (_busy) return;
    final expected = _attempt?.preview ?? _preview;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final institutionId = await widget.consultMembership();
      if (!mounted) return;
      setState(() {
        _mustConsult = false;
        if (institutionId != null) {
          if (expected != null && expected.institution.id == institutionId) {
            _joined = InstitutionCodeJoinResult(
              institution: expected.institution,
              alreadyLinked: true,
            );
          } else if (_joined?.institution.id != institutionId) {
            _linkedElsewhere = true;
          }
          _attempt = null;
          _preview = null;
          _code.clear();
          _message =
              'Vínculo institucional confirmado. No enviaremos otro ingreso.';
        } else if (_hasLink) {
          _message =
              'El vínculo local no coincide con la consulta. Sal de esta pantalla y actualiza tu perfil antes de continuar.';
        } else {
          _message = _attempt == null
              ? 'No tienes una institución vinculada.'
              : 'Todavía no tienes institución vinculada. Puedes reintentar el mismo envío, sin cambiar el código ni el intento.';
        }
      });
      if (institutionId != null) await _refreshAfterJoin();
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustConsult = true;
          _message =
              'No pudimos consultar tu vínculo. Conservamos el intento: no lo reenvíes hasta consultar de nuevo.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requests() async {
    // Abrir solicitudes no reenvía el ingreso: también está permitido cuando
    // hace falta reconciliarlo. Al regresar, _consult mantiene esa protección.
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRequests();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    // La solicitud pudo cancelarse o aprobarse en la otra pantalla. Consultar el
    // vínculo antes de habilitar acciones, sin descartar un envío incierto.
    await _consult();
    if (!mounted || _mustConsult || _hasLink) return;
    if (_attempt == null &&
        isInstitutionStudentCode(normalizeInstitutionStudentCode(_code.text))) {
      await _previewCode();
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    final leave = await _dialogs.show(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Salir sin continuar?'),
        content: Text(
          _attempt == null
              ? 'Se descartará el código escrito en esta pantalla.'
              : 'El ingreso podría haberse guardado. Al volver, consulta tu vínculo antes de iniciar otro intento. El código no se guardará en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (!mounted || leave != true) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String _error(Object error, String fallback) =>
      error is ApiError &&
          ['400', '403', '404', '409', '429'].contains(error.code)
      ? '$fallback ${error.message}'
      : fallback;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && (_allowExit || (_code.text.isEmpty && _attempt == null)),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) _exit();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Unirme a una institución')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_busy && !_confirming) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(liveRegion: true, child: Text(_message!)),
            ),
          if (_hasLink) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Institución vinculada',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_joined != null) Text(_joined!.institution.name),
                    const SizedBox(height: 8),
                    const Text(
                      'No se te asignó un grupo automáticamente. Puedes consultar tus grupos desde Mi institución y grupos. No se realizan traslados por código.',
                    ),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _consult,
              child: const Text('Actualizar mi vínculo'),
            ),
          ] else ...[
            const Text(
              'Pide al propietario el código privado de estudiantes. Consultarlo no te une automáticamente.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('student-institution-code-input'),
              controller: _code,
              enabled: !_busy && _attempt == null,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              textCapitalization: TextCapitalization.characters,
              maxLength: 64,
              decoration: const InputDecoration(
                labelText: 'Código de estudiantes',
                hintText: 'SPI-…',
                helperText: 'No es el código temporal de grupo.',
              ),
              onChanged: (_) => setState(() {
                _preview = null;
                _message = null;
              }),
              onSubmitted: (_) => _previewCode(),
            ),
            if (_attempt == null)
              FilledButton.icon(
                key: const Key('preview-student-institution-code'),
                onPressed: _busy || _mustConsult ? null : _previewCode,
                icon: const Icon(Icons.search),
                label: const Text('Consultar institución'),
              ),
            if (_preview case final preview?) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        preview.institution.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview.alreadyLinked
                            ? 'Ya perteneces a esta institución. Actualiza tu vínculo para verlo en la app.'
                            : 'Comprueba el nombre antes de confirmar. Ingresarás como estudiante y necesitarás un código de grupo aparte.',
                      ),
                      const SizedBox(height: 12),
                      if (preview.alreadyLinked)
                        OutlinedButton(
                          onPressed: _busy ? null : _consult,
                          child: const Text('Actualizar mi vínculo'),
                        )
                      else
                        FilledButton.icon(
                          key: const Key('join-student-institution-code'),
                          onPressed: _busy || _mustConsult ? null : _join,
                          icon: const Icon(Icons.how_to_reg_outlined),
                          label: Text(
                            _attempt == null
                                ? 'Unirme a esta institución'
                                : 'Reintentar mismo ingreso',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (_attempt != null || _mustConsult)
              OutlinedButton.icon(
                key: const Key('consult-student-code-membership'),
                onPressed: _busy ? null : _consult,
                icon: const Icon(Icons.refresh),
                label: const Text('Consultar mi vínculo'),
              ),
            const SizedBox(height: 16),
            const Text(
              'También puedes revisar o cancelar tus solicitudes de ingreso.',
            ),
            TextButton(
              onPressed: _busy ? null : _requests,
              child: const Text('Consultar mis solicitudes de ingreso'),
            ),
          ],
        ],
      ),
    ),
  );
}

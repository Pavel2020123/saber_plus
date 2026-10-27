import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../domain/student_institution_code.dart';
import '../domain/student_institution_request.dart';
import 'institution_code_confirmation.dart';

/// Estado privado en memoria de esta pantalla. No usar preferencias/analítica.
class InstitutionStudentCodeOwner extends StatefulWidget {
  const InstitutionStudentCodeOwner({
    super.key,
    required this.repository,
    required this.copy,
  });
  final StudentInstitutionCodeRepository repository;
  final Future<void> Function(String code) copy;
  @override
  State<InstitutionStudentCodeOwner> createState() =>
      _InstitutionStudentCodeOwnerState();
}

class _InstitutionStudentCodeOwnerState
    extends State<InstitutionStudentCodeOwner>
    with WidgetsBindingObserver {
  InstitutionStudentCode? _owned;
  final _dialogs = InstitutionCodeConfirmation();
  ({String id, int revision})? _operation;
  bool _busy = false,
      _mustConsult = false,
      _allowExit = false,
      _confirming = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _dialogs.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _owned = null;
    _operation = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    final expectedInstitutionId = _owned?.institution.id;
    setState(() {
      _busy = true;
      _owned = null;
      _message = null;
    });
    try {
      final current = await widget.repository.own();
      if (!mounted) return;
      if (expectedInstitutionId != null &&
          current.institution.id != expectedInstitutionId) {
        throw const FormatException(
          'La institución cambió. Abre nuevamente esta pantalla.',
        );
      }
      setState(() {
        _owned = current;
        _mustConsult = false;
        final operation = _operation;
        if (operation != null) {
          if (current.operationId == operation.id &&
              current.revision == operation.revision + 1) {
            _operation = null;
            _message = 'Renovación confirmada al consultar el código vigente.';
          } else if (current.revision != operation.revision) {
            _operation = null;
            _message =
                'El código cambió en otra operación. Se muestra la versión vigente; no reenviamos la anterior.';
          } else {
            _message =
                'No se observa esta renovación. Puedes reintentar la misma operación.';
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustConsult = true;
          _message =
              'No pudimos consultar el código vigente. No lo generes ni compartas hasta consultar de nuevo.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate() async {
    final owned = _owned;
    if (_busy ||
        _mustConsult ||
        owned == null ||
        owned.revision >= 2147483647) {
      return;
    }
    setState(() {
      _busy = true;
      _confirming = _operation == null;
    });
    try {
      if (_operation == null) {
        final accepted = await _dialogs.show(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: Text(
              owned.code == null
                  ? 'Generar código de estudiantes'
                  : '¿Renovar el código?',
            ),
            content: Text(
              owned.code == null
                  ? 'Quien reciba este código podrá ingresar a la institución como estudiante, si hay cupo. Compártelo solo con personas autorizadas.'
                  : 'El código anterior dejará de funcionar para nuevos ingresos. Los estudiantes ya vinculados conservarán su acceso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
        if (!mounted || accepted != true) return;
        setState(() => _confirming = false);
        _operation = (id: newStudentRequestId(), revision: owned.revision);
      }
      final operation = _operation!;
      final result = await widget.repository.rotate(
        operationId: operation.id,
        revision: operation.revision,
      );
      if (!mounted) return;
      setState(() {
        _owned = owned.rotated(result);
        _operation = null;
        _mustConsult = false;
        _message = 'Código de estudiantes confirmado.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _mustConsult = true;
          _message =
              'No se pudo confirmar la renovación. Consulta el código vigente antes de reintentar o compartir.';
          if (error is ApiError &&
              ['400', '403', '409', '429'].contains(error.code)) {
            _message = '$_message ${error.message}';
          }
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

  Future<void> _copy() async {
    final code = _owned?.code;
    if (_busy || _mustConsult || _operation != null || code == null) return;
    setState(() => _busy = true);
    try {
      await widget.copy(code);
      if (mounted) {
        setState(
          () => _message =
              'Código copiado. Compártelo solo con estudiantes autorizados por un medio de confianza.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'No pudimos copiar el código. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    final leave = await _dialogs.show(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Salir de esta operación?'),
        content: const Text(
          'La renovación podría haberse guardado. Al volver, consulta el código vigente antes de generar otro.',
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy && (_operation == null || _allowExit),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !_busy) _exit();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Código de estudiantes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text(
            'Este código permite unirse a la institución; no inscribe en un grupo ni concede permisos de profesor.',
          ),
          const SizedBox(height: 12),
          if (_busy && !_confirming) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(liveRegion: true, child: Text(_message!)),
            ),
          OutlinedButton.icon(
            key: const Key('consult-owner-student-code'),
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Consultar código vigente'),
          ),
          if (_owned case final owned?) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      owned.institution.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (!_mustConsult &&
                        _operation == null &&
                        owned.code != null) ...[
                      SelectableText(
                        owned.code!,
                        key: const Key('private-student-code'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('copy-student-code'),
                        onPressed: _busy ? null : _copy,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copiar para compartir'),
                      ),
                      const Text(
                        'Al copiarlo saldrá de esta pantalla al portapapeles del dispositivo. Renueva el código si se difunde.',
                      ),
                    ] else if (owned.code == null &&
                        !_mustConsult &&
                        _operation == null)
                      const Text(
                        'Todavía no has generado un código de estudiantes.',
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('rotate-student-code'),
                      onPressed:
                          _busy || _mustConsult || owned.revision >= 2147483647
                          ? null
                          : _rotate,
                      icon: const Icon(Icons.key_rounded),
                      label: Text(
                        _operation != null
                            ? 'Reintentar misma renovación'
                            : owned.code == null
                            ? 'Generar código'
                            : 'Renovar código',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

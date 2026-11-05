import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/network/api_error.dart';
import '../../institutions/domain/student_institution_request.dart';
import '../domain/private_profile_photo.dart';

class PrivateProfilePhotoBoard extends StatefulWidget {
  const PrivateProfilePhotoBoard({
    super.key,
    required this.userId,
    required this.repository,
    required this.pick,
  });
  final String userId;
  final PrivateProfilePhotoRepository repository;
  final Future<Uint8List?> Function() pick;
  @override
  State<PrivateProfilePhotoBoard> createState() =>
      _PrivateProfilePhotoBoardState();
}

class _PrivateProfilePhotoBoardState extends State<PrivateProfilePhotoBoard> {
  PrivateProfilePhoto? _photo;
  Uint8List? _draft, _pixels;
  String? _operation, _message, _deletingId;
  int? _operationRevision;
  int _generation = 0;
  bool _loading = true,
      _working = false,
      _uncertain = false,
      _deleteUncertain = false,
      _error = false,
      _allowLeave = false,
      _askingLeave = false;
  bool get _busy => _loading || _working;
  bool get _hasPending =>
      _draft != null || _operation != null || _deleteUncertain;
  bool _alive(int generation) => mounted && generation == _generation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _evict(Uint8List? bytes) {
    if (bytes != null) {
      unawaited(
        ResizeImage.resizeIfNeeded(512, 512, MemoryImage(bytes)).evict(),
      );
    }
  }

  @override
  void dispose() {
    _generation++;
    _evict(_draft);
    _evict(_pixels);
    _draft = _pixels = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PrivateProfilePhotoBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId ||
        widget.repository != oldWidget.repository) {
      _generation++;
      _evict(_draft);
      _evict(_pixels);
      _draft = _pixels = null;
      _photo = null;
      _operation = _deletingId = _message = null;
      _operationRevision = null;
      _working = _uncertain = _deleteUncertain = _error = _allowLeave =
          _askingLeave = false;
      _load();
    }
  }

  String _failure(Object error) => error is ApiError
      ? error.message
      : 'No pudimos completar la operación. Revisa tu conexión e intenta nuevamente.';

  Future<void> _display(
    PrivateProfilePhoto photo,
    int generation,
    String? message,
  ) async {
    if (!_alive(generation)) return;
    _evict(_pixels);
    setState(() {
      _photo = photo;
      _pixels = null;
      _message = message;
      _error = false;
    });
    if (photo.fileId == null) return;
    try {
      final pixels = await widget.repository.content(photo);
      if (_alive(generation)) setState(() => _pixels = pixels);
    } on Object {
      if (_alive(generation)) {
        setState(() {
          _message = message == null
              ? 'No pudimos mostrar tu foto. Actualiza para consultarla.'
              : '$message No pudimos mostrar la imagen; actualiza para consultarla.';
          _error = true;
        });
      }
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _evict(_pixels);
    setState(() {
      _loading = true;
      _message = null;
      _pixels = null;
      _photo = null;
    });
    try {
      final photo = await widget.repository.load();
      await _display(photo, generation, null);
    } on Object catch (error) {
      if (_alive(generation)) {
        setState(() {
          _message = _failure(error);
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    if (_busy || _operation != null || _deleteUncertain) return;
    final generation = ++_generation;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final bytes = await widget.pick();
      if (!_alive(generation) || bytes == null) return;
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const ApiError(
          code: 'selection',
          message: 'Selecciona una imagen de hasta 5 MiB.',
        );
      }
      _evict(_draft);
      setState(() {
        _draft = Uint8List.fromList(bytes);
        _error = false;
      });
    } on Object catch (error) {
      if (_alive(generation)) {
        setState(() {
          _message = _failure(error);
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _accept(PrivatePhotoReceipt receipt, int generation) async {
    if (!_alive(generation)) return;
    if (receipt.state == PrivatePhotoOperationState.prepared) {
      setState(() {
        _uncertain = true;
        _message =
            'La carga sigue preparada, pero no está guardada como tu foto. Puedes consultar de nuevo o reenviar la misma selección.';
        _error = false;
      });
      return;
    }
    _evict(_draft);
    setState(() {
      _draft = null;
      _operation = null;
      _operationRevision = null;
      _uncertain = false;
    });
    await _display(
      receipt.photo,
      generation,
      receipt.state == PrivatePhotoOperationState.active
          ? 'Tu foto privada quedó guardada.'
          : 'Esa selección ya no está vigente. Consultamos tu foto actual.',
    );
  }

  Future<void> _send() async {
    if (_busy || _draft == null || _photo == null || _deleteUncertain) return;
    final generation = ++_generation;
    _operation ??= newStudentRequestId();
    _operationRevision ??= _photo!.revision;
    setState(() {
      _working = true;
      _message = null;
      _uncertain = false;
    });
    try {
      final receipt = await widget.repository.upload(
        _operation!,
        _operationRevision!,
        _draft!,
      );
      await _accept(receipt, generation);
    } on Object catch (error) {
      if (_alive(generation)) {
        setState(() {
          final rejected =
              error is ApiError &&
              ['400', '413', '422', '429'].contains(error.code);
          _uncertain = !rejected;
          if (rejected) {
            _operation = null;
            _operationRevision = null;
          }
          _message = rejected
              ? _failure(error)
              : 'No pudimos confirmar el guardado. Consulta su estado o reenvía la misma selección; no haremos una carga distinta.';
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _consult() async {
    if (_busy || _operation == null) return;
    final generation = ++_generation;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final receipt = await widget.repository.operation(_operation!);
      await _accept(receipt, generation);
    } on Object catch (error) {
      if (_alive(generation)) {
        setState(() {
          _message = error is ApiError && error.code == '404'
              ? 'Todavía no hay recibo. Eso no confirma que la carga se haya cancelado. Consulta de nuevo o reenvía la misma selección.'
              : _failure(error);
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy || _operation == null) return;
    final generation = ++_generation;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final receipt = await widget.repository.cancel(_operation!);
      await _accept(receipt, generation);
      if (_alive(generation) && !_error) {
        setState(() => _message = 'La carga pendiente quedó cancelada.');
      }
    } on Object {
      if (_alive(generation)) {
        setState(() {
          _message =
              'No pudimos confirmar la cancelación. Consulta el estado de la carga; puede que ya se haya guardado.';
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _remove({bool retry = false}) async {
    if (_busy ||
        _photo?.fileId == null ||
        _draft != null ||
        _operation != null) {
      return;
    }
    if (!retry) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: const Text('¿Quitar tu foto privada?'),
          content: const Text(
            'Tu cuenta conservará el icono predeterminado. Esta acción no cambia tu progreso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitar foto'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    final generation = ++_generation;
    _deletingId = _photo!.fileId;
    _evict(_pixels);
    setState(() {
      _working = true;
      _message = null;
      _pixels = null;
    });
    try {
      final removed = await widget.repository.remove(_photo!.revision);
      if (!_alive(generation)) return;
      setState(() {
        _deleteUncertain = false;
        _deletingId = null;
      });
      await _display(
        removed.photo,
        generation,
        removed.cleanupPending
            ? 'La foto ya no es accesible. El servidor tiene pendiente terminar el borrado de sus bytes.'
            : 'Tu foto privada quedó retirada.',
      );
    } on Object {
      if (_alive(generation)) {
        setState(() {
          _deleteUncertain = true;
          _error = true;
          _message =
              'No pudimos confirmar la retirada. La ocultamos en esta pantalla; comprueba el estado antes de continuar.';
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _checkRemoval() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final photo = await widget.repository.load();
      if (!_alive(generation)) return;
      if (photo.fileId == _deletingId) {
        setState(() {
          _photo = photo;
          _message =
              'La foto todavía figura guardada. Puedes volver a solicitar su retirada.';
          _error = true;
        });
      } else {
        setState(() {
          _deleteUncertain = false;
          _deletingId = null;
        });
        await _display(
          photo,
          generation,
          photo.fileId == null
              ? 'La retirada quedó confirmada.'
              : 'La foto cambió en otra sesión. Consultamos la versión actual.',
        );
      }
    } on Object catch (error) {
      if (_alive(generation)) {
        setState(() {
          _message = _failure(error);
          _error = true;
        });
      }
    } finally {
      if (_alive(generation)) setState(() => _working = false);
    }
  }

  Future<void> _leave() async {
    if (_askingLeave) return;
    _askingLeave = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('¿Salir de tu foto privada?'),
        content: const Text(
          'La selección no se conservará en este dispositivo. Si enviaste una carga o retirada, salir no la cancela en el servidor. Al volver, consulta el estado de tu foto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _askingLeave = false;
    if (leave != true || !mounted) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = _draft ?? _pixels;
    return PopScope<Object?>(
      canPop: _allowLeave || (!_working && !_hasPending),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi foto privada', maxLines: 2),
          toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 24
              ? MediaQuery.textScalerOf(context).scale(20) * 2.4
              : null,
          actions: [
            IconButton(
              tooltip: 'Actualizar foto guardada',
              onPressed: _busy || _hasPending ? null : _load,
              icon: const Icon(Icons.refresh_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Una foto para ti',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solo tú puedes verla. No aparecerá en rankings, juegos ni directorios.',
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surfaceContainerHighest,
                            ),
                            child: preview == null
                                ? const Icon(Icons.person_outline, size: 72)
                                : Image.memory(
                                    preview,
                                    cacheWidth: 512,
                                    cacheHeight: 512,
                                    fit: BoxFit.cover,
                                    semanticLabel: _draft == null
                                        ? 'Tu foto privada guardada'
                                        : 'Vista previa de la foto seleccionada',
                                    errorBuilder: (_, _, _) => Semantics(
                                      label: 'Vista previa no disponible',
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _draft != null
                                ? 'Selección sin guardar'
                                : _deleteUncertain
                                ? 'Retirada sin confirmar'
                                : _photo?.fileId == null
                                ? 'Sin foto todavía'
                                : 'Foto guardada',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PNG, JPG o WEBP estático · hasta 5 MiB',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_busy) ...[
                    const LinearProgressIndicator(
                      semanticsLabel: 'Procesando tu foto privada',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_message != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _error
                              ? colors.errorContainer
                              : colors.primaryContainer,
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _error
                                ? colors.onErrorContainer
                                : colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_photo == null && !_busy)
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Reintentar consulta'),
                    ),
                  if (_photo != null && !_deleteUncertain) ...[
                    OutlinedButton.icon(
                      key: const Key('private-photo-pick'),
                      onPressed: _busy || _operation != null ? null : _pick,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _draft == null ? 'Elegir una foto' : 'Elegir otra foto',
                      ),
                    ),
                    if (_draft != null) ...[
                      const SizedBox(height: 12),
                      if (_uncertain)
                        FilledButton.icon(
                          key: const Key('private-photo-receipt'),
                          onPressed: _busy ? null : _consult,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Consultar estado de la carga'),
                        ),
                      if (_uncertain) const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('private-photo-save'),
                        onPressed: _busy ? null : _send,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _uncertain
                              ? 'Reenviar la misma selección'
                              : 'Guardar foto privada',
                        ),
                      ),
                      if (_operation == null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  _evict(_draft);
                                  setState(() {
                                    _draft = null;
                                    _message = null;
                                  });
                                },
                          child: const Text('Descartar selección'),
                        ),
                      if (_uncertain)
                        TextButton(
                          onPressed: _busy ? null : _cancel,
                          child: const Text('Cancelar carga pendiente'),
                        ),
                    ],
                    if (_photo!.fileId != null &&
                        _draft == null &&
                        _operation == null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('private-photo-remove'),
                        onPressed: _busy ? null : () => _remove(),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Quitar foto guardada'),
                      ),
                    ],
                  ],
                  if (_deleteUncertain) ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : _checkRemoval,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Comprobar retirada'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _remove(retry: true),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Reintentar retirada'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'La selección no se sube hasta que pulses Guardar. Necesitas conexión; esta foto no se añade a la biblioteca offline.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../domain/private_institution_evidence.dart';
import 'private_evidence_controller.dart';

class PrivateEvidenceBoard extends StatefulWidget {
  const PrivateEvidenceBoard({
    super.key,
    required this.controller,
    required this.pick,
    required this.export,
  });
  final PrivateEvidenceController controller;
  final Future<InstitutionEvidenceDraft?> Function() pick;
  final Future<bool> Function(InstitutionEvidenceFile, Uint8List) export;
  @override
  State<PrivateEvidenceBoard> createState() => _PrivateEvidenceBoardState();
}

class _PrivateEvidenceBoardState extends State<PrivateEvidenceBoard> {
  static const _touchStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(48, 48)),
  );
  bool _working = false, _allowLeave = false, _asking = false;
  String? _message;
  PrivateEvidenceController get c => widget.controller;
  bool get _busy => _working || c.busy;
  @override
  void initState() {
    super.initState();
    c.refresh();
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              style: _touchStyle,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: _touchStyle,
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _local(Future<void> Function() action) async {
    if (_busy || !c.alive) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await action();
    } on Object catch (error) {
      if (mounted && c.alive) {
        setState(
          () => _message = error is ApiError
              ? error.message
              : 'No pudimos completar la operación. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _pick() => _local(() async {
    final selected = await widget.pick();
    if (mounted && c.alive && selected != null) c.select(selected);
  });

  Future<void> _export(InstitutionEvidenceFile file) => _local(() async {
    final consent = await _confirm(
      'Exportar copia privada',
      'Solo exporta documentos que reconozcas. Los PDF no se han analizado con antivirus. '
          'La copia guardada fuera de SaberPlus no podrá revocarse ni eliminarse desde la app.',
      'Elegir destino',
    );
    if (!consent || !mounted || !c.alive) return;
    final bytes = await c.repository.content(file);
    if (!mounted || !c.alive) return;
    final saved = await widget.export(file, bytes);
    if (mounted && c.alive) {
      setState(
        () => _message = saved
            ? 'Copia exportada. Consérvala en un lugar seguro.'
            : 'Exportación cancelada. No se confirmó una copia nueva.',
      );
    }
  });

  Future<void> _withdraw(InstitutionEvidenceFile file) async {
    if (_busy) return;
    await _local(() async {
      final consent = await _confirm(
        'Retirar adjunto',
        'Dejará de estar disponible para consultar. Si la limpieza física tarda, '
            'te lo indicaremos. No se borrarán las copias ya exportadas.',
        'Retirar',
      );
      if (consent && mounted && c.alive) await c.withdraw(file);
    });
  }

  Future<void> _leave() async {
    if (_asking || _busy || !mounted) return;
    _asking = true;
    final consent = await _confirm(
      '¿Salir de los adjuntos?',
      c.operationId != null || c.withdrawing != null
          ? 'Hay una operación sin confirmar. Salir no la cancela ni borra el archivo del servidor. '
                'Conviene consultar su estado antes de salir. Se perderá la selección local para reintentar.'
          : 'La selección aún no se ha enviado. Se descartará al salir.',
      'Salir',
    );
    _asking = false;
    if (consent && mounted) {
      setState(() => _allowLeave = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _cancelUpload() => _local(() async {
    final consent = await _confirm(
      'Cancelar envío pendiente',
      'Consultaremos el servidor. Si el envío sigue preparado, retiraremos la reserva. '
          'Si ya se guardó, te lo mostraremos para que decidas si retirarlo. '
          'Una respuesta perdida no confirma la cancelación.',
      'Consultar y cancelar',
    );
    if (consent && mounted && c.alive) await c.cancelUpload();
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => PopScope(
      canPop: _allowLeave || (!_busy && !c.pending),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          outlinedButtonTheme: OutlinedButtonThemeData(
            style:
                Theme.of(
                  context,
                ).outlinedButtonTheme.style?.merge(_touchStyle) ??
                _touchStyle,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style:
                Theme.of(context).filledButtonTheme.style?.merge(_touchStyle) ??
                _touchStyle,
          ),
          textButtonTheme: TextButtonThemeData(
            style:
                Theme.of(context).textButtonTheme.style?.merge(_touchStyle) ??
                _touchStyle,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(title: const Text('Adjuntos privados')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Verificación institucional',
                      style: MediaQuery.textScalerOf(context).scale(1) > 1.5
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Solo tú y el equipo ADMIN pueden consultar estos adjuntos. '
                      'No adjuntes trabajos ni documentos personales de estudiantes. '
                      'Imágenes PNG/JPG/WEBP o PDF, hasta 5 MiB por archivo.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tras resolver la solicitud se conservarán privados durante 90 días. '
                      'El servidor confirma el plazo y el acceso.',
                    ),
                    const SizedBox(height: 16),
                    if (_busy)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Procesando adjunto',
                      ),
                    if (_message != null || c.message != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(_message ?? c.message!),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : c.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar adjuntos'),
                    ),
                    if (c.listing == null && !_busy)
                      const Text('Actualiza para consultar los adjuntos.'),
                    if (c.listing != null) ...[
                      const SizedBox(height: 16),
                      Text('${c.listing!.files.length} de 3 adjuntos'),
                      if (c.listing!.files.isEmpty)
                        const Text('Todavía no hay adjuntos disponibles.'),
                      for (final file in c.listing!.files)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  file.mime == 'application/pdf'
                                      ? 'Documento PDF'
                                      : 'Imagen privada',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text('${(file.bytes / 1024).ceil()} KiB'),
                                if (file.expiresAt != null)
                                  Text(
                                    'Disponible hasta ${file.expiresAt!.toLocal()}',
                                  ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _export(file),
                                      child: const Text('Exportar copia'),
                                    ),
                                    if (c.listing!.canUpload)
                                      TextButton(
                                        onPressed: _busy || c.pending
                                            ? null
                                            : () => _withdraw(file),
                                        child: const Text('Retirar adjunto'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (c.listing!.canUpload &&
                          c.operationId == null &&
                          c.withdrawing == null)
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _pick,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Seleccionar archivo'),
                        ),
                      if (!c.listing!.canUpload)
                        const Text(
                          'La solicitud no admite nuevos adjuntos en este momento.',
                        ),
                    ],
                    if (c.draft != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Selección local: ${(c.draft!.bytes.length / 1024).ceil()} KiB. No se envía automáticamente.',
                      ),
                      FilledButton(
                        onPressed: _busy ? null : c.upload,
                        child: Text(
                          c.operationId == null
                              ? 'Subir adjunto privado'
                              : 'Reintentar el mismo envío',
                        ),
                      ),
                      if (c.operationId == null)
                        TextButton(
                          onPressed: _busy ? null : c.discardSelection,
                          child: const Text('Descartar selección'),
                        ),
                    ],
                    for (final retired in c.cleanupPending)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Adjunto retirado · limpieza física pendiente',
                              ),
                              const Text(
                                'Ya no está disponible. El servidor volverá a intentar eliminar sus bytes.',
                              ),
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => c.retryCleanup(retired.id),
                                child: const Text('Reintentar limpieza'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (c.uncertain) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Hay una operación sin confirmar. No se iniciará otro envío.',
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : c.reconcile,
                        child: const Text('Consultar operación pendiente'),
                      ),
                      if (c.operationId != null)
                        TextButton(
                          onPressed: _busy ? null : _cancelUpload,
                          child: const Text('Cancelar envío preparado'),
                        ),
                      if (c.withdrawing != null)
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _withdraw(c.withdrawing!),
                          child: const Text('Reintentar retirada'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

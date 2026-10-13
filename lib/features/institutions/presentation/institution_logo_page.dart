import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_logo_repository.dart';
import '../domain/institution_profile.dart';
import 'institution_directory_providers.dart';
import 'institution_logo.dart';
import 'institution_profile_page.dart';

class InstitutionLogoPage extends ConsumerWidget {
  const InstitutionLogoPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    final profiles = ref.watch(institutionProfileRepositoryProvider);
    final dio = ref.watch(dioProvider);
    return InstitutionLogoEditor(
      key: ValueKey((user?.id, profiles, dio)),
      profiles: profiles,
      logos: RemoteInstitutionLogoRepository(dio),
      pick: () async {
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          requestFullMetadata: false,
        );
        if (file == null) return null;
        if (await file.length() > 3 * 1024 * 1024) {
          throw const FormatException('La imagen supera 3 MB.');
        }
        return file.readAsBytes();
      },
      onSaved: (id) {
        ref.invalidate(institutionDirectoryProvider);
        ref.invalidate(institutionDirectoryDetailProvider(id));
      },
    );
  }
}

class InstitutionLogoEditor extends StatefulWidget {
  const InstitutionLogoEditor({
    super.key,
    required this.profiles,
    required this.logos,
    required this.pick,
    required this.onSaved,
  });
  final InstitutionProfileRepository profiles;
  final InstitutionLogoRepository logos;
  final Future<Uint8List?> Function() pick;
  final ValueChanged<String> onSaved;
  @override
  State<InstitutionLogoEditor> createState() => _InstitutionLogoEditorState();
}

class _InstitutionLogoEditorState extends State<InstitutionLogoEditor> {
  InstitutionProfile? _profile;
  Uint8List? _draft;
  bool _busy = true, _mustReload = false, _allowExit = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final profile = await widget.profiles.load();
      if (!mounted) return;
      setState(() {
        if (_profile?.id != profile.id || !profile.canEdit) _draft = null;
        _profile = profile;
        _mustReload = false;
        _message = _draft == null
            ? null
            : 'Logo actual consultado. Compara tu selección antes de guardarla.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustReload = true;
          _message = 'No pudimos consultar el logo. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await widget.pick();
      if (!mounted || bytes == null) return;
      if (bytes.isEmpty || bytes.length > 3 * 1024 * 1024) {
        throw const FormatException('Tamaño no válido');
      }
      // La vista previa no sustituye la decodificación y validación del servidor.
      setState(() => _draft = bytes);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'No pudimos abrir esa imagen. Revisa el permiso de fotos y elige un PNG, JPG o WEBP de hasta 3 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save({bool remove = false}) async {
    final profile = _profile;
    if (_busy ||
        _mustReload ||
        profile == null ||
        !profile.canEdit ||
        (!remove && _draft == null)) {
      return;
    }
    if (remove) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Eliminar el logo?'),
          content: const Text(
            'La institución aparecerá con el icono predeterminado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.logos.save(profile, remove ? null : _draft);
      if (!mounted) return;
      setState(() {
        _profile = result;
        _draft = null;
        _message = remove ? 'Logo eliminado.' : 'Logo institucional guardado.';
      });
      widget.onSaved(result.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustReload = true;
          _message =
              'No se pudo confirmar el cambio. Conservamos tu selección. Consulta la versión actual antes de volver a guardar. Usa PNG, JPG o WEBP estático de hasta 3 MB y 16 megapíxeles.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir sin confirmar los cambios?'),
        content: const Text(
          'Se descartará la selección. Si no se confirmó un envío, consulta el logo al volver.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return PopScope(
      canPop: _allowExit || (!_busy && _draft == null && !_mustReload),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Logo institucional')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (profile != null) ...[
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Text('Logo publicado'),
                Center(
                  child: profile.logoUrl == null
                      ? const Icon(Icons.school_outlined, size: 96)
                      : InstitutionLogo(path: profile.logoUrl, size: 120),
                ),
                if (_draft != null) ...[
                  const SizedBox(height: 20),
                  const Text('Vista previa · Recorte cuadrado centrado'),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _draft!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 200,
                          height: 80,
                          child: Text(
                            'No se puede mostrar esta imagen. Selecciona otra.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (profile.canEdit) ...[
                  const Text(
                    'PNG, JPG o WEBP estático. Máximo 3 MB y 16 megapíxeles. Comprueba que el logo completo quede dentro del recorte.',
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Seleccionar imagen'),
                  ),
                  if (_draft != null) ...[
                    FilledButton(
                      onPressed: _busy || _mustReload ? null : () => _save(),
                      child: const Text('Guardar logo'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _draft = null),
                      child: const Text('Descartar selección'),
                    ),
                  ],
                  if (profile.logoUrl != null)
                    TextButton(
                      onPressed: _busy || _mustReload
                          ? null
                          : () => _save(remove: true),
                      child: const Text('Eliminar logo'),
                    ),
                ] else
                  const Text('Solo el propietario puede cambiar el logo.'),
              ],
              if (_message != null)
                Semantics(liveRegion: true, child: Text(_message!)),
              OutlinedButton(
                onPressed: _busy ? null : _load,
                child: const Text('Consultar versión actual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

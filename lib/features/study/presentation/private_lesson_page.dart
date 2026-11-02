import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media/private_lesson_cache.dart';

/// A separate reader: no solutions, PDF files, completion writes or XP.
class PrivateLessonPage extends ConsumerStatefulWidget {
  const PrivateLessonPage({super.key, required this.contextId});
  final String contextId;
  @override
  ConsumerState<PrivateLessonPage> createState() => _PrivateLessonPageState();
}

class _PrivateLessonPageState extends ConsumerState<PrivateLessonPage>
    with WidgetsBindingObserver {
  PrivateLessonCache? _cache;
  PrivateLessonCopy? _copy;
  Timer? _expiry;
  int _ticket = 0;
  bool _busy = true;
  int _networkRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cache = ref.read<PrivateLessonCache>(privateLessonCacheProvider);
      cache.addListener(_onCacheChanged);
      _cache = cache;
      _networkRevision = _cache!.networkRevision;
      unawaited(_load());
    });
  }

  void _hide() {
    _expiry?.cancel();
    _copy = null;
    _ticket++;
  }

  void _invalidate() {
    if (!mounted) return;
    setState(_hide);
    unawaited(_load());
  }

  void _onCacheChanged() {
    if (!mounted) return;
    final reconnect = _cache!.networkRevision != _networkRevision;
    _networkRevision = _cache!.networkRevision;
    setState(() {
      _hide();
      _busy = false;
    });
    // A denial must not immediately launch another request and resurrect data.
    if (reconnect) unawaited(_load());
  }

  Future<void> _load() async {
    final cache = _cache;
    if (!mounted || cache == null) return;
    final ticket = ++_ticket;
    setState(() {
      _copy = null;
      _busy = true;
    });
    _expiry?.cancel();
    PrivateLessonCopy? result;
    try {
      result = await cache.open(widget.contextId);
    } on Object {
      /* No plaintext fallback after denial. */
    }
    if (!mounted || ticket != _ticket) return;
    setState(() {
      _copy = result;
      _busy = false;
    });
    if (result != null) {
      _expiry = Timer(result.remaining, () {
        if (mounted) {
          setState(() {
            _hide();
            _busy = false;
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _invalidate();
    } else if (mounted) {
      setState(() {
        _hide();
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _ticket++;
    _cache?.removeListener(_onCacheChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lección privada · 72 h'),
      actions: [
        IconButton(
          tooltip: 'Revalidar contenido privado',
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : _copy == null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Revalida el contenido privado con conexión. Al vencer las 72 horas o confirmar una denegación, la copia deja de estar disponible.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Revalidar'),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _copy!.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Copia privada protegida. Se revalida al volver la conexión; no es un PDF exportado.',
              ),
              const SizedBox(height: 12),
              if (_copy!.image case final bytes?)
                _PrivateImage(key: ValueKey(bytes), bytes: bytes),
              const SizedBox(height: 16),
              SelectableText(_copy!.content),
            ],
          ),
  );
}

/// Never enters Flutter ImageCache: revoke/logout disposal releases decoded pixels.
class _PrivateImage extends StatefulWidget {
  const _PrivateImage({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<_PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<_PrivateImage> {
  ui.Image? _image;
  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  Future<void> _decode() async {
    ui.Codec? codec;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(widget.bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > 2560 || descriptor.height > 2560) return;
      codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      if (frame.image.width > 2560 || frame.image.height > 2560) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } on Object {
      /* No network fallback for invalid private pixels. */
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? const Text('Preparando imagen privada…')
      : RawImage(image: _image, fit: BoxFit.contain);
}

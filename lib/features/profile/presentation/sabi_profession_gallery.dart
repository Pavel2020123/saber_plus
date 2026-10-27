import 'package:flutter/material.dart';

import 'sabi_profession_illustration.dart';

/// Optional introduction to professional fields, with no user/result input,
/// ranking, persistence or family-to-profession assignment.
class SabiProfessionGallery extends StatefulWidget {
  const SabiProfessionGallery({super.key});

  @override
  State<SabiProfessionGallery> createState() => _SabiProfessionGalleryState();
}

class _SabiProfessionGalleryState extends State<SabiProfessionGallery> {
  bool _expanded = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profession = SabiProfession.values[_index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Ámbitos profesionales en imágenes',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplos visuales de ámbitos profesionales para explorar por tu cuenta. '
              'Esta galería es independiente de tus respuestas y no recomienda una carrera.',
            ),
            const SizedBox(height: 8),
            Semantics(
              expanded: _expanded,
              child: TextButton.icon(
                key: const Key('sabi-gallery-toggle'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less
                      : Icons.collections_bookmark_outlined,
                ),
                label: Text(_expanded ? 'Cerrar galería' : 'Ver galería'),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  profession.displayName,
                  key: const Key('sabi-gallery-title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: SabiProfessionIllustration(profession: profession),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Ámbito ${_index + 1} de ${SabiProfession.values.length}',
                  key: const Key('sabi-gallery-position'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('sabi-gallery-previous'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _index == 0
                        ? null
                        : () => setState(() => _index--),
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Anterior'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('sabi-gallery-next'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: _index == SabiProfession.values.length - 1
                        ? null
                        : () => setState(() => _index++),
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

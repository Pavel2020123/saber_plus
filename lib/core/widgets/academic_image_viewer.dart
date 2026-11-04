import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/widget_previews.dart';

class AcademicImageViewer extends StatefulWidget {
  const AcademicImageViewer({
    super.key,
    required this.label,
    required this.child,
  });
  final String label;
  final Widget child;

  @override
  State<AcademicImageViewer> createState() => _AcademicImageViewerState();
}

class _AcademicImageViewerState extends State<AcademicImageViewer> {
  final controller = TransformationController();
  Size viewport = Size.zero;
  void zoom(double scale) {
    final bounded = scale.clamp(1.0, 8.0);
    controller.value = Matrix4.diagonal3Values(bounded, bounded, 1)
      ..setTranslationRaw(
        viewport.width * (1 - bounded) / 2,
        viewport.height * (1 - bounded) / 2,
        0,
      );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('close-image-viewer'),
                  tooltip: 'Cerrar imagen ampliada',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Pellizca para ampliar, arrastra para mover o toca dos veces.',
            ),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  viewport = constraints.biggest;
                  return GestureDetector(
                    onDoubleTap: () => zoom(
                      controller.value.getMaxScaleOnAxis() > 1.01 ? 1 : 2.5,
                    ),
                    child: InteractiveViewer(
                      key: const Key('academic-image-zoom'),
                      transformationController: controller,
                      minScale: 1,
                      maxScale: 8,
                      child: SizedBox.expand(
                        child: Center(child: widget.child),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Reducir imagen',
                onPressed: () =>
                    zoom(controller.value.getMaxScaleOnAxis() / 1.5),
                icon: const Icon(LucideIcons.zoomOut),
              ),
              TextButton(
                onPressed: () => zoom(1),
                child: const Text('Restablecer'),
              ),
              IconButton(
                tooltip: 'Ampliar imagen',
                onPressed: () =>
                    zoom(controller.value.getMaxScaleOnAxis() * 1.5),
                icon: const Icon(LucideIcons.zoomIn),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'Visor de imagen · Celular', size: Size(390, 844))
Widget academicImageViewerPreview() => const MaterialApp(
  home: AcademicImageViewer(
    label: 'Gráfica de ejemplo',
    child: ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Imagen de contenido\n100 %',
          style: TextStyle(fontSize: 30, color: Colors.black),
        ),
      ),
    ),
  ),
);

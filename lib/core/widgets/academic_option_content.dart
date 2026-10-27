import 'package:flutter/material.dart';

import 'academic_image.dart';

/// Content only: the owning screen keeps selection, correction and scoring.
/// The text remains visible when an optional image is unavailable.
class AcademicOptionContent extends StatelessWidget {
  const AcademicOptionContent({super.key, required this.text, this.imageUrl});

  final String text;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text),
      if (imageUrl?.trim().isNotEmpty ?? false) ...[
        const SizedBox(height: 8),
        AcademicImage(
          value: imageUrl!,
          label: 'Imagen de la opción: $text',
          maxImageHeight: 240,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    ],
  );
}

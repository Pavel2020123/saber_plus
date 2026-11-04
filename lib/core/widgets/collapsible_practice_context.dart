import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Only hides contextual labels, never the question or its evaluation controls.
class CollapsiblePracticeContext extends StatefulWidget {
  const CollapsiblePracticeContext({super.key, required this.label});
  final String label;
  @override
  State<CollapsiblePracticeContext> createState() =>
      _CollapsiblePracticeContextState();
}

class _CollapsiblePracticeContextState
    extends State<CollapsiblePracticeContext> {
  bool _hidden = false;
  @override
  Widget build(BuildContext context) => _hidden
      ? Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() => _hidden = false),
            child: const Text('Mostrar tema'),
          ),
        )
      : Row(
          children: [
            Expanded(child: Text(widget.label)),
            IconButton(
              tooltip: 'Ocultar tema de la práctica',
              onPressed: () => setState(() => _hidden = true),
              icon: const Icon(LucideIcons.x),
            ),
          ],
        );
}

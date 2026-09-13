import 'package:flutter/material.dart';

/// Cards grow with their text instead of clipping at a fixed aspect ratio.
class TeacherMetricsLayout extends StatelessWidget {
  const TeacherMetricsLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 12.0;
      final minimumWidth =
          160 * MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = constraints.maxWidth >= minimumWidth * 2 + spacing
          ? 2
          : 1;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../app/theme.dart';
import 'practice_folders.dart';

@Preview(name: 'Carpetas · Celular', size: Size(390, 844))
@Preview(name: 'Carpetas · Tableta', size: Size(800, 1000))
Widget practiceFoldersPreview() => MaterialApp(
  theme: SaberPlusTheme.light,
  home: Scaffold(body: PracticeFolders(onOpen: (_) {})),
);

@Preview(
  name: 'Carpeta abierta · Letra ampliada',
  size: Size(390, 844),
  textScaleFactor: 1.8,
)
Widget openPracticeFolderPreview() => MaterialApp(
  theme: SaberPlusTheme.light,
  home: PracticeFolderDialog(
    folder: practiceFolders().firstWhere((folder) => folder.id == 'games'),
  ),
);

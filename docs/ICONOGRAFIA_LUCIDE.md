# Iconografía aprobada — SaberPlus

Implementación del 26 de octubre de 2026. Dependencia comunitaria
`lucide_icons_flutter: ^4.0.1`; no es un paquete oficial del equipo Lucide.
Fuente: https://pub.dev/packages/lucide_icons_flutter

## Selección aprobada

| Sección | Identificador Dart |
| --- | --- |
| Inicio | LucideIcons.house |
| Estudiar | LucideIcons.bookOpenText |
| Practicar | LucideIcons.gamepad2 |
| Progreso | LucideIcons.chartArea |
| Más | LucideIcons.menu |
| Preferencias | LucideIcons.slidersHorizontal |
| Experiencia | LucideIcons.zap |
| Diagnóstico | LucideIcons.clipboardCheck |
| Tiempo / Pomodoro | LucideIcons.timer |
| Institución | LucideIcons.school |
| Perfil | LucideIcons.userRound |
| Ranking | LucideIcons.crown |
| Continuar | LucideIcons.play |
| Siguiente | LucideIcons.arrowRight |

## Criterios y alcance

Usar la fuente regular outline: trazo nominal de aproximadamente 2 px en
el diseño de 24 px, con variación proporcional al tamaño. No aplicar
`FontWeight` ni importar grosores distintos para simular iconos seleccionados.
Se conservan tamaños y colores existentes, incluidos los tamaños compactos
de XP y los iconos grandes de estados informativos.

La barra estudiantil conserva las cinco pestañas, etiquetas, callbacks,
indicador seleccionado y colores del tema. El dibujo es outline tanto activo
como inactivo; la selección sigue diferenciada por el indicador y su color.

Archivos de UI actualizados:

- `lib/features/shared/presentation/student_shell.dart`
- `lib/features/dashboard/presentation/student_dashboard_page.dart`
- `lib/features/dashboard/presentation/more_page.dart`
- `lib/features/dashboard/presentation/teacher_dashboard_page.dart`
- `lib/features/focus/presentation/pomodoro_card.dart`
- `lib/core/wellbeing/study_break_reminder.dart`
- `lib/core/preferences/preferences_page.dart`
- `lib/features/ranking/presentation/ranking_page.dart`
- `lib/features/profile/presentation/academic_profile_page.dart`
- `lib/features/academic/presentation/diagnostic_overview_page.dart`
- `lib/features/progress/presentation/progress_page.dart`

Se reemplazan los accesos e indicadores correspondientes dentro de estos
archivos, no toda la colección Material de la aplicación. Iconos de logros,
seguridad, sincronización, áreas académicas y otras funciones no aprobadas
se conservan. No se cambia el arte de juegos, logos, mascotas, ilustraciones,
insignias, rutas, cálculos ni reglas académicas. OV-1 y backend sin cambios.

## Verificación

- La versión instalada contiene los 14 identificadores exactos.
- `test/lucide_icons_test.dart`: 14 identificadores distintos de la fuente
  Lucide y construcción de widgets sin excepciones.
- `test/widget_test.dart`: iconos de las cinco pestañas, misma variante outline
  seleccionada y cambio de índice al navegar a Estudiar.
- Conjunto dirigido de inicio, accesibilidad, navegación y alcance de
  presentación: 59/59 pruebas aprobadas.
- `flutter analyze`: sin incidencias.
- Las vistas previas de widgets cargan la fuente Lucide del propio paquete.

No se ha recompilado ni instalado una APK con estos cambios y no se declara
validación en celular. No se realizó commit ni push en esta entrega.

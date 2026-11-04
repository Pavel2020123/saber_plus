import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../domain/institutional_access.dart';

class InstitutionalAccessCard extends StatelessWidget {
  const InstitutionalAccessCard({
    required this.access,
    this.username,
    this.onRefresh,
    this.refreshing = false,
    super.key,
  });

  final InstitutionalAccess access;
  final String? username;
  final VoidCallback? onRefresh;
  final bool refreshing;

  String get _description {
    if (!access.hasAssignment &&
        access.state == InstitutionalLicenseState.active) {
      return 'Tu institución debe asignarte un cupo para iniciar actividades nuevas. Tu historial no se borra.';
    }
    return switch (access.state) {
      InstitutionalLicenseState.noLicense =>
        'Tu institución aún no tiene una licencia habilitada. Consulta con tu responsable; tu historial no se borra.',
      InstitutionalLicenseState.scheduled =>
        'La cobertura todavía no comienza. Podrás iniciar actividades cuando el backend confirme su inicio y tu asignación.',
      InstitutionalLicenseState.active =>
        'Tu cobertura institucional está activa. El servidor valida el acceso a cada actividad.',
      InstitutionalLicenseState.expired =>
        'No puedes iniciar actividades nuevas. Conservas el historial permitido. Los diagnósticos y simulacros iniciados con cobertura activa solo se entregan hasta su plazo original y, como máximo, 24 horas después del vencimiento. El servidor confirma si el intento todavía es válido.',
      InstitutionalLicenseState.suspended =>
        'La institución debe revisar tu acceso. No se habilitan actividades nuevas ni entregas pendientes mientras exista suspensión.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String dateLabel(DateTime value) {
      final colombia = value.toUtc().subtract(const Duration(hours: 5));
      final localizations = MaterialLocalizations.of(context);
      return '${localizations.formatShortDate(colombia)}, ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(colombia))} (Colombia)';
    }

    return Card(
      key: const Key('institutional-access-card'),
      color: access.canStartPractice
          ? colors.secondaryContainer
          : colors.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.school_outlined, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    access.statusLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_description),
            if (access.state == InstitutionalLicenseState.scheduled &&
                access.startsAt != null) ...[
              const SizedBox(height: 12),
              Text('Inicio acordado: ${dateLabel(access.startsAt!)}.'),
            ],
            if (username != null) ...[
              const SizedBox(height: 12),
              Text('Usuario institucional: $username'),
              const Text('Es un usuario de acceso, no un buzón de correo.'),
            ],
            if (access.endsAt != null) ...[
              const SizedBox(height: 12),
              Text('Fin de cobertura: ${dateLabel(access.endsAt!)}.'),
            ],
            const SizedBox(height: 8),
            Text(
              'Última validación: ${dateLabel(access.validatedAt)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: refreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  refreshing ? 'Actualizando acceso…' : 'Actualizar acceso',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@Preview(
  name: 'Licencia vencida · teléfono',
  group: 'LIC-3',
  size: Size(375, 760),
)
@Preview(
  name: 'Licencia vencida · texto grande oscuro',
  group: 'LIC-3',
  size: Size(375, 1000),
  textScaleFactor: 2,
  brightness: Brightness.dark,
)
Widget institutionalAccessCardPreview() => MaterialApp(
  theme: ThemeData(colorSchemeSeed: Colors.indigo),
  darkTheme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.dark,
  ),
  home: Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: InstitutionalAccessCard(
          access: InstitutionalAccess(
            institutionId: 'preview-school',
            state: InstitutionalLicenseState.expired,
            managedAccount: true,
            hasAssignment: true,
            practiceAllowed: false,
            historyAllowed: true,
            validatedAt: DateTime.utc(2026, 11, 3),
          ),
          username: 'estudiante@colegio.example',
        ),
      ),
    ),
  ),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/environment.dart';
import '../../../core/network/staging_connection_probe.dart';

class StagingConnectionSheet extends ConsumerWidget {
  const StagingConnectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(stagingConnectionReportProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conexión con staging',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(ref.watch(appConfigProvider).apiBaseUrl),
            const SizedBox(height: 16),
            report.when(
              loading: () => const Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Comprobando el servidor. Si estaba suspendido, el primer paso puede tardar hasta un minuto. Puedes cerrar esta ventana para cancelar.',
                  ),
                ],
              ),
              error: (error, stack) => const Text(
                'No se pudo iniciar la comprobación. Revisa la configuración de staging.',
              ),
              data: (report) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      report.passed
                          ? 'Conexión básica verificada'
                          : 'Comprobación incompleta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final check in report.checks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        check.passed
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                      ),
                      title: Text(check.label),
                      subtitle: Text(check.message),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta prueba no inicia sesión, no crea cuentas y no comprueba que todas las migraciones o el contenido estén publicados. Los datos de staging son datos reales de prueba, no la demostración local.',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: report.isLoading
                  ? null
                  : () => ref.invalidate(stagingConnectionReportProvider),
              child: const Text('Volver a comprobar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

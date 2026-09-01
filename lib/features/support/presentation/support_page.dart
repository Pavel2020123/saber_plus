import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/support_configuration.dart';
import 'support_providers.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final support = ref.watch(supportConfigurationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(supportConfigurationProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: support.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SupportError(
          message: _message(error),
          onRetry: () => ref.invalidate(supportConfigurationProvider),
        ),
        data: (data) => ListView(
          key: const Key('support-list'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      '¿Necesitas ayuda con la app?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Este canal resuelve problemas de cuenta, acceso o funcionamiento. No reemplaza una tutoría académica.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ContactCard(configuration: data),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nunca envíes tu contraseña, códigos de verificación ni datos de pago por WhatsApp.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.configuration});

  final SupportConfiguration configuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = configuration.trustedWhatsappUri;
    if (uri == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.schedule_rounded, size: 34),
              SizedBox(height: 10),
              Text(
                'El canal de soporte no está disponible en este momento.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WhatsApp', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(configuration.whatsappNumber ?? 'Canal configurado'),
            const SizedBox(height: 8),
            Text(
              'Mensaje inicial: “${configuration.message}”',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('open-whatsapp-support'),
              onPressed: () => _open(context, ref, uri),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir WhatsApp'),
            ),
            TextButton.icon(
              key: const Key('copy-whatsapp-number'),
              onPressed: configuration.whatsappNumber == null
                  ? null
                  : () => _copy(context, configuration.whatsappNumber!),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar número'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    var opened = false;
    try {
      opened = await ref.read(supportLinkOpenerProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir WhatsApp.')),
      );
    }
  }

  Future<void> _copy(BuildContext context, String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Número copiado.')));
    }
  }
}

class _SupportError extends StatelessWidget {
  const _SupportError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _message(Object error) => switch (error) {
  ApiError value => value.message,
  _ => 'No pudimos consultar el canal de soporte.',
};

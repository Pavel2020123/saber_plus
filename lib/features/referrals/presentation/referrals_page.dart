import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import 'referral_providers.dart';

class ReferralsPage extends ConsumerWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(referralSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar a estudiar'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref.invalidate(referralSummaryProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ReferralError(
          message: _message(error),
          onRetry: () => ref.invalidate(referralSummaryProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(referralSummaryProvider.future),
          child: ListView(
            key: const Key('referrals-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.group_add_outlined, size: 34),
                      const SizedBox(height: 12),
                      Text(
                        'Invita a tus compañeros',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'La otra persona debe escribir tu código al crear su cuenta. Nunca compartimos su nombre ni sus resultados contigo.',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tu código',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        data.code,
                        key: const Key('referral-code'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('copy-referral-invitation'),
                        onPressed: () => _copy(context, data.shareText),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copiar invitación'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people_outline_rounded),
                  title: Text(
                    '${data.totalInvitations} invitaciones registradas',
                  ),
                  subtitle: const Text(
                    'Solo mostramos el registro; la actividad académica de cada persona es privada.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.card_giftcard_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Beneficio del programa',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(data.benefit.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Actividad reciente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (data.invitations.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(
                      child: Text(
                        'Todavía no se ha registrado nadie con tu código.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                for (var index = 0; index < data.invitations.length; index++)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline_rounded),
                      ),
                      title: Text('Invitación ${index + 1}'),
                      subtitle: Text(
                        'Registro: ${_formatDate(data.invitations[index].registeredAt)}',
                      ),
                      trailing: const Icon(Icons.check_circle_outline_rounded),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitación copiada. Ya puedes compartirla.'),
      ),
    );
  }
}

class _ReferralError extends StatelessWidget {
  const _ReferralError({required this.message, required this.onRetry});

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
  _ => 'No pudimos cargar tus invitaciones. Intenta nuevamente.',
};

String _formatDate(DateTime date) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import 'battle_providers.dart';

class BlockedRivalsPage extends ConsumerWidget {
  const BlockedRivalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedRivalsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rivales bloqueados')),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_message(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(blockedRivalsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(blockedRivalsProvider.future),
          child: ListView(
            key: const Key('blocked-rivals-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Lista privada'),
                  subtitle: Text(
                    'Conservamos el bloqueo sin mostrar la identidad de la otra persona.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No has bloqueado rivales.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                for (final item in items)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_off_outlined),
                      ),
                      title: Text(item.alias),
                      subtitle: Text('Bloqueado ${_date(item.createdAt)}'),
                      trailing: TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(battleRepositoryProvider)
                                .unblock(item.id);
                            ref.invalidate(blockedRivalsProvider);
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_message(error))),
                            );
                          }
                        },
                        child: const Text('Desbloquear'),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _message(Object error) {
  if (error is ApiError) return error.message;
  if (error is StateError) return error.message;
  return 'No fue posible cargar los bloqueos.';
}

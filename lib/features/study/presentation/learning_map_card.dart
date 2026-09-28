import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/learning_map_repository.dart';
import '../domain/learning_map.dart';
import 'study_providers.dart';

final learningMapProvider = FutureProvider.autoDispose
    .family<LearningMap, LearningMapRequest>((ref, request) {
      final user = ref.watch(sessionControllerProvider).user;
      if (user == null) {
        throw StateError('Inicia sesión para consultar el mapa.');
      }
      final repository = user.isDemo
          ? DemoLearningMapRepository()
          : ref.watch(learningMapRepositoryProvider);
      return repository.load(request);
    });

class LearningMapCard extends ConsumerWidget {
  const LearningMapCard({super.key, required this.request});
  final LearningMapRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(learningMapProvider(request));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa de aprendizaje',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Estas bases pueden ayudarte. Puedes seguir estudiando esta lección sin completarlas.',
            ),
            map.when(
              skipLoadingOnRefresh: false,
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Consultando mapa',
                ),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No pudimos consultar el mapa. Puede faltar conexión o el contenido ya no estar disponible.',
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(learningMapProvider(request)),
                    child: const Text('Reintentar mapa'),
                  ),
                ],
              ),
              data: (data) => data.route.isEmpty
                  ? const Text(
                      'No hay bases publicadas configuradas. Esto no indica dominio del tema.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(learningMapProvider(request)),
                          child: const Text('Actualizar mapa'),
                        ),
                        const Text(
                          'Recorrido sugerido · leer una lección no demuestra dominio.',
                        ),
                        // Render long maps on demand instead of building thousands of tiles in the lesson.
                        TextButton.icon(
                          icon: const Icon(Icons.route),
                          label: Text('Ver ${data.route.length} bases'),
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _MapRoute(request: request),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoute extends ConsumerWidget {
  const _MapRoute({required this.request});
  final LearningMapRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(learningMapProvider(request));
    final catalog = ref.watch(studyCatalogProvider(request.area));
    final progress = ref.watch(studyProgressProvider).valueOrNull;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar recorrido'),
            ),
            if (catalog.isLoading) const LinearProgressIndicator(),
            if (catalog.hasError)
              TextButton(
                onPressed: () =>
                    ref.invalidate(studyCatalogProvider(request.area)),
                child: const Text(
                  'No se pudo consultar el catálogo. Reintentar',
                ),
              ),
            Expanded(
              child: map.when(
                skipLoadingOnReload: false,
                data: (data) => ListView.builder(
                  itemCount: data.route.length,
                  itemBuilder: (context, index) {
                    final node = data.route[index];
                    final available =
                        !catalog.isLoading &&
                        !catalog.hasError &&
                        catalog.valueOrNull?.findSubtopic(
                              node.themeId,
                              node.id,
                            ) !=
                            null;
                    final direct = data.previous.any((n) => n.id == node.id);
                    final read = (progress?.percentageFor(node.id) ?? 0) >= 100;
                    return ListTile(
                      title: Text('${index + 1}. ${node.name}'),
                      subtitle: Text(
                        '${node.themeName} · ${direct ? 'Base directa' : 'Base anterior'}${read ? ' · Lección completada, no dominio acreditado' : ''}${available ? '' : ' · No disponible en el catálogo actual'}',
                      ),
                      trailing: available
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: !available
                          ? null
                          : () {
                              final router = GoRouter.of(context);
                              ref.invalidate(
                                studyCatalogProvider(request.area),
                              );
                              Navigator.pop(context);
                              router.push(
                                '/student/study/${request.area.slug}/${Uri.encodeComponent(node.themeId)}/${Uri.encodeComponent(node.id)}',
                              );
                            },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text(
                  'El mapa ya no está disponible. Cierra y vuelve a intentarlo.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

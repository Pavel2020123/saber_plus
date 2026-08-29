import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/drift_favorite_repository.dart';
import '../domain/favorite_models.dart';
import 'favorite_providers.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _FavoritesError(onRetry: () => ref.invalidate(favoritesProvider)),
        data: (items) => items.isEmpty
            ? const _EmptyFavorites()
            : ListView.separated(
                key: const Key('favorites-list'),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                      child: Text(
                        'Tus favoritos se guardan en este dispositivo para encontrarlos rápidamente.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  final favorite = items[index - 1];
                  return _FavoriteTile(
                    favorite: favorite,
                    onOpen: () => context.push(favorite.route),
                    onRemove: () => _remove(context, ref, favorite),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    AcademicFavorite favorite,
  ) async {
    try {
      await ref
          .read(favoriteRepositoryProvider)
          .remove(favorite.userId, favorite.identity);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${favorite.title} se eliminó de favoritos.')),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar tus favoritos.')),
      );
    }
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.favorite,
    required this.onOpen,
    required this.onRemove,
  });

  final AcademicFavorite favorite;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('favorite-${favorite.itemId}'),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onOpen,
      leading: const CircleAvatar(child: Icon(Icons.menu_book_rounded)),
      title: Text(favorite.title),
      subtitle: Text('${favorite.area.label} · ${favorite.parentTitle}'),
      trailing: IconButton(
        key: Key('remove-favorite-${favorite.itemId}'),
        tooltip: 'Eliminar de favoritos',
        onPressed: onRemove,
        icon: const Icon(Icons.bookmark_remove_outlined),
      ),
    ),
  );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border_rounded, size: 58),
          const SizedBox(height: 14),
          Text(
            'Aún no tienes favoritos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          const Text(
            'Abre una lección y toca el marcador para guardarla aquí.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/student/study'),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Explorar lecciones'),
          ),
        ],
      ),
    ),
  );
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar tus favoritos.'),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../domain/academic_search_models.dart';
import 'academic_search_providers.dart';

enum _SearchFilter { all, lessons, questions }

class AcademicSearchPage extends ConsumerStatefulWidget {
  const AcademicSearchPage({super.key});

  @override
  ConsumerState<AcademicSearchPage> createState() => _AcademicSearchPageState();
}

class _AcademicSearchPageState extends ConsumerState<AcademicSearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  _SearchFilter _filter = _SearchFilter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(academicSearchIndexProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar contenido')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              key: const Key('academic-search-field'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Ejemplo: regla de tres',
                labelText: 'Tema o concepto',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todo',
                  selected: _filter == _SearchFilter.all,
                  onSelected: () => setState(() => _filter = _SearchFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Lecciones',
                  selected: _filter == _SearchFilter.lessons,
                  onSelected: () =>
                      setState(() => _filter = _SearchFilter.lessons),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Preguntas',
                  selected: _filter == _SearchFilter.questions,
                  onSelected: () =>
                      setState(() => _filter = _SearchFilter.questions),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: index.when(
              data: (value) =>
                  _SearchResults(index: value, query: _query, filter: _filter),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _SearchError(
                message: error is ApiError
                    ? error.message
                    : 'No pudimos preparar la búsqueda académica.',
                onRetry: () => ref.invalidate(academicSearchIndexProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.index,
    required this.query,
    required this.filter,
  });

  final AcademicSearchIndex index;
  final String query;
  final _SearchFilter filter;

  @override
  Widget build(BuildContext context) {
    if (query.trim().length < 2) {
      return const _SearchHint();
    }
    final type = switch (filter) {
      _SearchFilter.all => null,
      _SearchFilter.lessons => AcademicSearchType.lesson,
      _SearchFilter.questions => AcademicSearchType.questionPractice,
    };
    final results = index.search(query, type: type);
    if (results.isEmpty) return _EmptySearch(query: query.trim());
    return ListView.separated(
      key: const Key('academic-search-results'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: results.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 8) : const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'}',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return _ResultCard(result: results[index - 1]);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final AcademicSearchResult result;

  @override
  Widget build(BuildContext context) {
    final isLesson = result.type == AcademicSearchType.lesson;
    return Card(
      child: InkWell(
        key: Key('academic-search-result-${result.identity}'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(result.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(
                  isLesson ? Icons.menu_book_rounded : Icons.quiz_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLesson ? 'Lección' : 'Banco de preguntas',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.subtopicName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${result.area.label} · ${result.themeName}'),
                    if (isLesson && result.excerpt != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        result.excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (!isLesson) ...[
                      const SizedBox(height: 7),
                      Text(
                        '${result.questionCount} preguntas disponibles · Inicia una práctica protegida',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search_rounded, size: 64),
          SizedBox(height: 14),
          Text(
            'Escribe al menos dos letras para buscar en lecciones y subtemas con preguntas.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 62),
          const SizedBox(height: 14),
          Text(
            'No encontramos contenido para “$query”.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Prueba con el nombre de un tema, subtema, área o concepto.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 62),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

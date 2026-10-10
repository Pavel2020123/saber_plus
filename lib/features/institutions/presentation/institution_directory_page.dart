import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/institution_directory_repository.dart';
import 'institution_directory_providers.dart';

class InstitutionDirectoryPage extends ConsumerStatefulWidget {
  const InstitutionDirectoryPage({super.key});
  @override
  ConsumerState<InstitutionDirectoryPage> createState() =>
      _InstitutionDirectoryPageState();
}

class _InstitutionDirectoryPageState
    extends ConsumerState<InstitutionDirectoryPage> {
  final _search = TextEditingController();
  var _query = '';
  var _page = 1;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _query = _search.text.trim();
      _page = 1;
    });
    ref.invalidate(institutionDirectoryProvider((query: _query, page: _page)));
  }

  @override
  Widget build(BuildContext context) {
    final key = (query: _query, page: _page);
    final state = ref.watch(institutionDirectoryProvider(key));
    final demo =
        ref.watch(institutionDirectoryRepositoryProvider)
            is DemoInstitutionDirectoryRepository;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar instituciones'),
        actions: [
          IconButton(
            tooltip: 'Actualizar directorio',
            onPressed: () => ref.invalidate(institutionDirectoryProvider(key)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (demo)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Demostración: instituciones ficticias, sin conexión al directorio real.',
                  ),
                ),
              ),
            const Text('Explora instituciones aprobadas en SaberPlus.'),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              maxLength: 120,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Nombre de la institución',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 16),
            if (_query.isNotEmpty) Text('Resultados para «$_query»'),
            state.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => Column(
                children: [
                  const Text(
                    'No pudimos cargar el directorio. Intenta nuevamente.',
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(institutionDirectoryProvider(key)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (data) => Column(
                children: [
                  if (data.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No encontramos instituciones para esta búsqueda.',
                      ),
                    ),
                  for (final item in data.items)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(item.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                InstitutionDirectoryDetailPage(id: item.id),
                          ),
                        ),
                      ),
                    ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _page > 1
                            ? () => setState(() => _page--)
                            : null,
                        child: const Text('Anterior'),
                      ),
                      Text('Página ${data.page}'),
                      TextButton(
                        onPressed: data.hasMore && _page < 10000
                            ? () => setState(() => _page++)
                            : null,
                        child: const Text('Siguiente'),
                      ),
                    ],
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

class InstitutionDirectoryDetailPage extends ConsumerWidget {
  const InstitutionDirectoryDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(institutionDirectoryDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Institución')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            state.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Column(
                children: [
                  const Text(
                    'No pudimos consultar esta institución. Puede que ya no esté disponible o haya un problema de conexión.',
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(institutionDirectoryDetailProvider(id)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Consultar esta ficha no te vincula a la institución. Las solicitudes de ingreso desde el directorio estarán disponibles en una próxima actualización.',
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

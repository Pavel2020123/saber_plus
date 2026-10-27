import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_directory_repository.dart';
import 'institution_directory_providers.dart';
import 'institution_directory_filters.dart';
import 'institution_logo.dart';
import 'student_institution_requests_page.dart';

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
  String? _department, _municipality;
  bool _filtersVisible = false;
  DirectoryQuery get _key => (
    query: _query,
    page: _page,
    department: _department,
    municipality: _municipality,
  );
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
    ref.invalidate(institutionDirectoryProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final key = _key;
    final state = ref.watch(institutionDirectoryProvider(key));
    final locationNames = <String>[];
    if (_department != null) {
      final departments = ref.watch(directoryDepartmentsProvider).asData?.value;
      for (final option in departments?.options ?? []) {
        if (option.code == _department) locationNames.add(option.name);
      }
      if (_municipality != null) {
        final municipalities = ref
            .watch(directoryMunicipalitiesProvider(_department!))
            .asData
            ?.value;
        for (final option in municipalities?.options ?? []) {
          if (option.code == _municipality) locationNames.add(option.name);
        }
      }
    }
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
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submit,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.tune, size: 20),
              onPressed: () =>
                  setState(() => _filtersVisible = !_filtersVisible),
              label: Text(
                _filtersVisible
                    ? 'Ocultar filtros de ubicación'
                    : 'Filtrar por ubicación',
              ),
            ),
            if (locationNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(locationNames.join(' · '))),
                  ],
                ),
              ),
            if (_filtersVisible)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: InstitutionDirectoryFilters(
                  department: _department,
                  municipality: _municipality,
                  onChanged: (department, municipality) => setState(() {
                    _department = department;
                    _municipality = municipality;
                    _page = 1;
                  }),
                ),
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
                        leading: InstitutionLogo(path: item.logoUrl, size: 40),
                        title: Text(item.name),
                        subtitle: Text(
                          item.locationLabel ??
                              'Ubicación pendiente de clasificar',
                        ),
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
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
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
                  InstitutionLogo(path: item.logoUrl, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    item.locationLabel ?? 'Ubicación pendiente de clasificar',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sobre la institución',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description?.trim().isNotEmpty == true
                        ? item.description!
                        : 'Esta institución todavía no ha añadido una presentación pública.',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Consultar esta ficha no te vincula a la institución.',
                  ),
                  if (user?.role == AppRole.student &&
                      user?.isDemo == false) ...[
                    const SizedBox(height: 12),
                    if (user?.institutionId == null)
                      FilledButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Solicitar ingreso'),
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentInstitutionRequestsPage(target: item),
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Ya perteneces a una institución. Las solicitudes no realizan traslados automáticos.',
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

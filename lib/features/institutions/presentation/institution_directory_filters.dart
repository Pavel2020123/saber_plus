import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/institution_territory_repository.dart';
import 'institution_territory_field.dart';

final directoryDepartmentsProvider =
    FutureProvider.autoDispose<TerritoryCatalogPage>(
      (ref) => ref.watch(institutionTerritoryRepositoryProvider).departments(),
    );
final directoryMunicipalitiesProvider = FutureProvider.autoDispose
    .family<TerritoryCatalogPage, String>(
      (ref, department) => ref
          .watch(institutionTerritoryRepositoryProvider)
          .municipalities(department),
    );

class InstitutionDirectoryFilters extends ConsumerWidget {
  const InstitutionDirectoryFilters({
    super.key,
    required this.department,
    required this.municipality,
    required this.onChanged,
  });
  final String? department, municipality;
  final void Function(String?, String?) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(directoryDepartmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        departments.when(
          skipLoadingOnRefresh: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(directoryDepartmentsProvider),
            child: const Text('Reintentar departamentos'),
          ),
          data: (page) => Column(
            children: [
              _select(
                'directory-department',
                'Departamento',
                department,
                page.options,
                (value) => onChanged(value, null),
              ),
              if (department != null) const SizedBox(height: 20),
              if (department != null)
                ref
                    .watch(directoryMunicipalitiesProvider(department!))
                    .when(
                      skipLoadingOnRefresh: false,
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => TextButton(
                        onPressed: () => ref.invalidate(
                          directoryMunicipalitiesProvider(department!),
                        ),
                        child: const Text('Reintentar municipios'),
                      ),
                      data: (municipalities) =>
                          municipalities.version != page.version
                          ? const Text(
                              'El catálogo cambió. Cierra y vuelve a abrir los filtros.',
                            )
                          : _select(
                              'directory-municipality',
                              'Municipio / unidad territorial',
                              municipality,
                              municipalities.options,
                              (value) => onChanged(department, value),
                            ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => onChanged(null, null),
          icon: const Icon(Icons.location_off_outlined, size: 18),
          label: const Text('Todas las ubicaciones'),
        ),
      ],
    );
  }

  Widget _select(
    String key,
    String label,
    String? value,
    List<TerritoryOption> options,
    ValueChanged<String?> change,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$key-${value ?? 'all'}'),
    initialValue: options.any((row) => row.code == value) ? value : '',
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    items: [
      const DropdownMenuItem(value: '', child: Text('Todos')),
      ...options.map(
        (row) => DropdownMenuItem(
          value: row.code,
          child: Text(row.name, overflow: TextOverflow.ellipsis),
        ),
      ),
    ],
    onChanged: (code) => change(code == '' ? null : code),
  );
}

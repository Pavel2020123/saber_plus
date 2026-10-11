import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_territory_repository.dart';

final institutionTerritoryRepositoryProvider =
    Provider<InstitutionTerritoryRepository>((ref) {
      final identity = ref.watch(
        sessionControllerProvider.select((s) => (s.user?.id, s.user?.isDemo)),
      );
      return identity.$2 == true
          ? DemoInstitutionTerritoryRepository()
          : RemoteInstitutionTerritoryRepository(ref.watch(dioProvider));
    });

class InstitutionTerritoryField extends StatefulWidget {
  const InstitutionTerritoryField({
    super.key,
    required this.repository,
    required this.onChanged,
    this.initialDepartment,
    this.initialMunicipality,
    this.enabled = true,
  });
  final InstitutionTerritoryRepository repository;
  final ValueChanged<InstitutionTerritorySelection?> onChanged;
  final String? initialDepartment, initialMunicipality;
  final bool enabled;
  @override
  State<InstitutionTerritoryField> createState() =>
      _InstitutionTerritoryFieldState();
}

class _InstitutionTerritoryFieldState extends State<InstitutionTerritoryField>
    with AutomaticKeepAliveClientMixin<InstitutionTerritoryField> {
  @override
  bool get wantKeepAlive => true;
  final _field = GlobalKey<FormFieldState<InstitutionTerritorySelection>>();
  TerritoryCatalogPage? _departments, _municipalities;
  String? _department, _municipality, _error;
  bool _loading = true;
  int _generation = 0;
  CancelToken? _cancel;
  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void didUpdateWidget(covariant InstitutionTerritoryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _loadDepartments();
  }

  @override
  void dispose() {
    _generation++;
    _cancel?.cancel();
    super.dispose();
  }

  int _start() {
    _cancel?.cancel();
    _cancel = CancelToken();
    _loading = true;
    _error = null;
    return ++_generation;
  }

  void _publish(InstitutionTerritorySelection? value) {
    _field.currentState?.didChange(value);
    widget.onChanged(value);
  }

  Future<void> _loadDepartments() async {
    final generation = _start();
    _departments = null;
    _municipalities = null;
    _department = null;
    _municipality = null;
    try {
      final page = await widget.repository.departments(cancelToken: _cancel);
      if (!mounted || generation != _generation) return;
      _publish(null);
      setState(() {
        _departments = page;
        _loading = false;
      });
      final initial = widget.initialDepartment;
      if (initial != null && page.options.any((row) => row.code == initial)) {
        await _loadMunicipalities(initial, restore: widget.initialMunicipality);
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _publish(null);
      setState(() {
        _loading = false;
        _error = 'No pudimos cargar los departamentos.';
      });
    }
  }

  Future<void> _loadMunicipalities(String department, {String? restore}) async {
    final generation = _start();
    _publish(null);
    setState(() {
      _department = department;
      _municipality = null;
      _municipalities = null;
    });
    try {
      final page = await widget.repository.municipalities(
        department,
        cancelToken: _cancel,
      );
      if (!mounted || generation != _generation) return;
      if (page.version != _departments!.version) {
        throw const FormatException('Versiones diferentes');
      }
      setState(() {
        _municipalities = page;
        _loading = false;
      });
      if (restore != null && page.options.any((row) => row.code == restore)) {
        _select(restore);
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error =
            'No pudimos cargar los municipios. Reintenta; si persiste, vuelve a abrir el formulario.';
      });
    }
  }

  void _select(String code) {
    final municipality = _municipalities!.options.firstWhere(
      (row) => row.code == code,
    );
    setState(() => _municipality = code);
    _publish(
      InstitutionTerritorySelection(
        _departments!.options.firstWhere((row) => row.code == _department),
        municipality,
        _municipalities!.version,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FormField<InstitutionTerritorySelection>(
      key: _field,
      validator: (value) => value == null || _loading
          ? 'Selecciona departamento y municipio de la sede.'
          : null,
      builder: (field) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubicación de la sede que representas'),
            const Text(
              'No solicitamos tu domicilio ni la ubicación de estudiantes.',
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('territory-department-${_department ?? 'none'}'),
              initialValue: _department,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Departamento / Bogotá D.C.',
              ),
              items: (_departments?.options ?? [])
                  .map(
                    (row) => DropdownMenuItem(
                      value: row.code,
                      child: Text(row.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled && _departments != null
                  ? (value) {
                      if (value != null) _loadMunicipalities(value);
                    }
                  : null,
            ),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'territory-municipality-${_department ?? 'none'}-${_municipality ?? 'none'}',
              ),
              initialValue: _municipality,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Municipio / distrito / unidad territorial',
              ),
              items: (_municipalities?.options ?? [])
                  .map(
                    (row) => DropdownMenuItem(
                      value: row.code,
                      child: Text(row.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: widget.enabled && !_loading && _municipalities != null
                  ? (value) {
                      if (value != null) _select(value);
                    }
                  : null,
            ),
            if (_loading)
              const LinearProgressIndicator(
                semanticsLabel: 'Cargando ubicación',
              ),
            if (_error != null) ...[
              Text(_error!),
              TextButton(
                onPressed: widget.enabled
                    ? () {
                        setState(() => _loading = true);
                        if (_department == null) {
                          _loadDepartments();
                        } else {
                          _loadMunicipalities(
                            _department!,
                            restore: widget.initialMunicipality,
                          );
                        }
                      }
                    : null,
                child: const Text('Reintentar ubicación'),
              ),
            ],
            if (field.hasError)
              Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

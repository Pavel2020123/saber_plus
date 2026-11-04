import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/booklet_activity.dart';
import 'booklet_exercise.dart';

final bookletActivitiesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, subtopicId) async {
      final user = ref.watch(sessionControllerProvider).user;
      if (user == null || user.isDemo) return [];
      final response = await ref
          .watch(dioProvider)
          .get<List<dynamic>>(
            '/cuadernillo',
            queryParameters: {'subtemaId': subtopicId},
          );
      if (response.data == null) throw const FormatException('Respuesta vacía');
      return response.data!
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    });

class BookletSection extends ConsumerWidget {
  const BookletSection({super.key, required this.subtopicId});
  final String subtopicId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookletActivitiesProvider(subtopicId));
    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => Column(
        children: [
          const Text(
            'No se pudieron consultar las actividades tipo cuadernillo.',
          ),
          TextButton(
            onPressed: () =>
                ref.invalidate(bookletActivitiesProvider(subtopicId)),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      data: (rows) => Column(
        children: [
          for (final row in rows)
            Card(
              child: ListTile(
                title: Text((row['contenido'] as Map)['title'] as String),
                subtitle: const Text(
                  'Actividad tipo cuadernillo · Familiarización',
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookletActivityPage(row: row),
                    ),
                  );
                  if (context.mounted) {
                    ref.invalidate(bookletActivitiesProvider(subtopicId));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class BookletActivityPage extends ConsumerStatefulWidget {
  const BookletActivityPage({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<BookletActivityPage> createState() =>
      _BookletActivityPageState();
}

class _BookletActivityPageState extends ConsumerState<BookletActivityPage> {
  late final BookletActivity activity;
  final selections = <String, String>{};
  final feedback = <String, String>{};
  Future<void> writeQueue = Future.value();
  bool loading = true;
  bool busy = false;
  bool submitted = false;
  String? message;
  String? owner;
  String get storageKey =>
      'booklet.v1.$owner.${activity.id}.${widget.row['version']}';
  @override
  void initState() {
    super.initState();
    activity = BookletActivity.fromJson(
      widget.row['id'] as String,
      Map<String, dynamic>.from(widget.row['contenido'] as Map),
    );
    owner = ref.read(sessionControllerProvider).user?.id;
    _restore();
  }

  Future<void> _restore() async {
    try {
      final value = await SharedPreferencesAsync().getString(storageKey);
      if (value != null) {
        final data = Map<String, dynamic>.from(jsonDecode(value) as Map);
        for (final entry in data.entries) {
          if (entry.value is String &&
              activity.acceptsSelection(entry.key, entry.value as String)) {
            selections[entry.key] = entry.value as String;
          }
        }
      }
    } on Object {
      message = 'No se pudo recuperar el borrador local.';
    }
    if (mounted) setState(() => loading = false);
  }

  void _select(String item, String choice) {
    if (busy || submitted || !activity.acceptsSelection(item, choice)) return;
    setState(() {
      selections[item] = choice;
      message = null;
    });
    final snapshot = jsonEncode(selections);
    writeQueue = writeQueue
        .then((_) => SharedPreferencesAsync().setString(storageKey, snapshot))
        .catchError((Object error) {
          if (mounted) {
            setState(
              () => message =
                  'La selección no pudo guardarse en este dispositivo.',
            );
          }
        });
  }

  Future<void> _submit() async {
    if (busy || submitted || !activity.isComplete(selections)) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/cuadernillo/${Uri.encodeComponent(activity.id)}/corregir',
            data: {'version': widget.row['version'], 'selections': selections},
          );
      if (!mounted || ref.read(sessionControllerProvider).user?.id != owner) {
        return;
      }
      final result = response.data!;
      for (final value in result['items'] as List) {
        final row = Map<String, dynamic>.from(value as Map);
        final correct = activity.choices.firstWhere(
          (c) => c.id == row['correctChoiceId'],
        );
        feedback[row['id'] as String] =
            '${row['correct'] == true ? 'Correcta' : 'Revisa tu respuesta'}. Respuesta: ${correct.label}. ${correct.text}\n${row['explanation']}';
      }
      setState(() {
        submitted = true;
        message =
            '${result['correct']} de ${result['total']} respuestas correctas. Práctica sin puntuación de diagnóstico.';
      });
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => message = error.response?.statusCode == 409
              ? 'La actividad cambió. Regresa a la lección y actualízala; tu borrador anterior se conserva.'
              : 'No se pudo corregir. Conservamos tus selecciones; vuelve a intentarlo.',
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => message =
              'No se pudo interpretar la corrección. Tus selecciones se conservan.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOwner = ref.watch(sessionControllerProvider).user?.id;
    if (owner == null || currentOwner != owner) {
      return const Scaffold(
        body: Center(child: Text('La sesión cambió. Vuelve a iniciar sesión.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Actividad tipo cuadernillo')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BookletExercise(
                        activity: activity,
                        selections: selections,
                        onSelect: _select,
                        feedback: feedback,
                        locked: busy || submitted,
                      ),
                      const SizedBox(height: 20),
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(message!, semanticsLabel: message),
                        ),
                      Text(
                        '${selections.length} de ${activity.items.length} respuestas seleccionadas',
                      ),
                      FilledButton(
                        onPressed:
                            busy ||
                                submitted ||
                                !activity.isComplete(selections)
                            ? null
                            : _submit,
                        child: Text(
                          busy ? 'Corrigiendo…' : 'Entregar actividad',
                        ),
                      ),
                      if (submitted)
                        TextButton(
                          onPressed: () => setState(() {
                            submitted = false;
                            feedback.clear();
                            message = null;
                          }),
                          child: const Text('Practicar nuevamente'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

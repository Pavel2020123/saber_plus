import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/academic_image.dart';

class LessonReadingCard {
  const LessonReadingCard(this.title, this.body);
  final String title;
  final String body;
}

/// Reads the panel's standard Markdown without changing stored lesson content.
/// Headings inside fenced code remain part of that code, not navigation cards.
List<LessonReadingCard> splitLessonCards(String markdown) {
  final cards = <LessonReadingCard>[];
  var title = '';
  var lines = <String>[];
  String? fence;
  void flush() {
    final body = lines.join('\n').trim();
    if (title.isNotEmpty || body.isNotEmpty) {
      cards.add(LessonReadingCard(title, body));
    }
    lines = [];
  }

  for (final line in markdown.replaceAll('\r\n', '\n').split('\n')) {
    final marker = RegExp(r'^\s{0,3}(`{3,}|~{3,})').firstMatch(line);
    if (marker != null) {
      final value = marker.group(1)!;
      if (fence == null) {
        fence = value;
      } else if (value[0] == fence[0] && value.length >= fence.length) {
        fence = null;
      }
      lines.add(line);
      continue;
    }
    final heading = fence == null
        ? RegExp(r'^\s{0,3}#{1,6}\s+(.+?)\s*#*\s*$').firstMatch(line)
        : null;
    if (heading == null) {
      lines.add(line);
    } else {
      flush();
      title = heading
          .group(1)!
          .replaceFirst(
            RegExp(
              r'^(Lectura|Ejemplo|Consejo|Resumen)\s*:\s*',
              caseSensitive: false,
            ),
            '',
          );
    }
  }
  flush();
  return cards;
}

abstract interface class LessonViewStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SharedLessonViewStore implements LessonViewStore {
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read(String key) => _preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

final lessonViewStoreProvider = Provider<LessonViewStore>(
  (ref) => SharedLessonViewStore(),
);

/// Reading position is not academic progress or completion. It stays local to
/// this device and is isolated by signed-in account and subtopic.
class LessonCardReader extends ConsumerStatefulWidget {
  const LessonCardReader({
    super.key,
    required this.userId,
    required this.subtopicId,
    required this.title,
    required this.markdown,
    required this.questionCount,
    required this.footer,
    required this.onOpenLink,
  });
  final String? userId;
  final String subtopicId;
  final String title;
  final String markdown;
  final int questionCount;
  final Widget footer;
  final ValueChanged<String> onOpenLink;
  @override
  ConsumerState<LessonCardReader> createState() => _LessonCardReaderState();
}

class _LessonCardReaderState extends ConsumerState<LessonCardReader> {
  var _index = 0;
  var _introHidden = false;
  var _questionsHidden = false;
  var _loading = true;
  var _generation = 0;
  var _direction = 1;
  double _dragDistance = 0;
  Future<void> _writes = Future.value();
  late List<LessonReadingCard> _cards;
  String get _key =>
      'saberplus.lesson-view.v1.'
      '${Uri.encodeComponent(widget.userId ?? "anonymous")}.'
      '${Uri.encodeComponent(widget.subtopicId)}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LessonCardReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.subtopicId != widget.subtopicId ||
        oldWidget.markdown != widget.markdown) {
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _cards = splitLessonCards(widget.markdown);
    _index = 0;
    _introHidden = false;
    _questionsHidden = false;
    _loading = true;
    try {
      await _writes;
      final raw = widget.userId == null
          ? null
          : await ref.read(lessonViewStoreProvider).read(_key);
      if (!mounted || generation != _generation) return;
      final data = raw == null ? null : jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        _introHidden = data['introHidden'] == true;
        _questionsHidden = data['questionsHidden'] == true;
        final savedIndex = data['index'];
        if (data['content'] == widget.markdown &&
            savedIndex is int &&
            savedIndex >= 0 &&
            savedIndex < _cards.length) {
          _index = savedIndex;
        }
      }
    } on Object {
      // A presentation preference must never prevent access to the lesson.
    }
    if (mounted && generation == _generation) {
      setState(() => _loading = false);
    }
  }

  void _save() {
    if (widget.userId == null) return;
    final key = _key;
    final LessonViewStore store;
    try {
      store = ref.read(lessonViewStoreProvider);
    } on Object {
      // Native preferences may be unavailable; reading must still work.
      return;
    }
    final value = jsonEncode({
      'content': widget.markdown,
      'index': _index,
      'introHidden': _introHidden,
      'questionsHidden': _questionsHidden,
    });
    _writes = _writes
        .then((_) => store.write(key, value))
        .catchError((Object _) {});
  }

  void _turn(int direction) {
    final next = _index + direction;
    if (next < 0 || next >= _cards.length) return;
    setState(() {
      _direction = direction;
      _index = next;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    final card = _cards.isEmpty ? null : _cards[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_introHidden)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '¡Vamos paso a paso!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        key: const Key('dismiss-lesson-intro'),
                        tooltip: 'Cerrar bienvenida de esta lección',
                        onPressed: () {
                          setState(() => _introHidden = true);
                          _save();
                        },
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Explora ${widget.title} con explicaciones y ejemplos. '
                          'Avanza a tu ritmo. ¡Ánimo, tú puedes!',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/Sabi_Inicio_Refuerzo.png',
                        width: 70,
                        height: 90,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (!_questionsHidden)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.questionCount} preguntas de práctica disponibles',
                ),
              ),
              IconButton(
                key: const Key('dismiss-lesson-question-count'),
                tooltip: 'Ocultar cantidad de preguntas',
                onPressed: () {
                  setState(() => _questionsHidden = true);
                  _save();
                },
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
        if (card != null) ...[
          GestureDetector(
            key: const Key('lesson-card-swipe'),
            onHorizontalDragStart: (_) => _dragDistance = 0,
            onHorizontalDragUpdate: (details) =>
                _dragDistance += details.primaryDelta ?? 0,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_dragDistance.abs() >= 45 || velocity.abs() >= 300) {
                _turn(
                  (_dragDistance.abs() >= 45 ? _dragDistance : velocity) < 0
                      ? 1
                      : -1,
                );
              }
            },
            child: AnimatedSize(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                switchInCurve: const Interval(
                  .18,
                  1,
                  curve: Curves.easeOutCubic,
                ),
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_direction * .07, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Card(
                  key: ValueKey('reading-card-$_index'),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            liveRegion: true,
                            label: 'Tarjeta ${_index + 1} de ${_cards.length}',
                            child: ExcludeSemantics(
                              child: Text(
                                '${_index + 1} / ${_cards.length}',
                                key: const Key('lesson-card-position'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (card.title.isNotEmpty) ...[
                          Semantics(
                            header: true,
                            child: Text(
                              card.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        MarkdownBody(
                          data: card.body,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ),
                          onTapLink: (_, href, _) {
                            if (href != null) widget.onOpenLink(href);
                          },
                          imageBuilder: (uri, _, alt) => AcademicImage(
                            value: uri.toString(),
                            label: alt ?? 'Imagen de la lección',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                key: const Key('lesson-card-previous'),
                tooltip: 'Tarjeta anterior',
                onPressed: _index == 0 ? null : () => _turn(-1),
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const Spacer(),
              IconButton(
                key: const Key('lesson-card-next'),
                tooltip: 'Tarjeta siguiente',
                onPressed: _index == _cards.length - 1 ? null : () => _turn(1),
                icon: const Icon(LucideIcons.arrowRight),
              ),
            ],
          ),
        ],
        if (_cards.isEmpty || _index == _cards.length - 1) widget.footer,
      ],
    );
  }
}

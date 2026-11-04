import 'package:flutter/material.dart';
import '../domain/booklet_activity.dart';
import '../../../core/widgets/academic_image.dart';

class BookletExercise extends StatelessWidget {
  const BookletExercise({
    super.key,
    required this.activity,
    required this.selections,
    required this.onSelect,
    this.feedback = const {},
    this.locked = false,
  });

  final BookletActivity activity;
  final Map<String, String> selections;
  final void Function(String itemId, String choiceId) onSelect;
  final Map<String, String> feedback;
  final bool locked;

  Future<void> _choose(BuildContext context, BookletItem item) async {
    if (locked) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .6,
        maxChildSize: .9,
        minChildSize: .3,
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Respuesta ${item.number}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final id in item.choiceIds)
              ListTile(
                title: Text('${_choice(id).label}. ${_choice(id).text}'),
                subtitle: _choice(id).imageUrl == null
                    ? null
                    : AcademicImage(
                        value: _choice(id).imageUrl!,
                        label: 'Imagen de la opción ${_choice(id).label}',
                        maxImageHeight: 180,
                      ),
                selected: selections[item.id] == id,
                onTap: () => Navigator.pop(context, id),
              ),
          ],
        ),
      ),
    );
    if (selected != null && !locked) onSelect(item.id, selected);
  }

  BookletChoice _choice(String id) =>
      activity.choices.firstWhere((choice) => choice.id == id);

  Widget _answer(BuildContext context, BookletItem item) {
    final selected = selections[item.id];
    return OutlinedButton(
      key: Key('booklet-answer-${item.id}'),
      onPressed: locked ? null : () => _choose(context, item),
      child: Text(
        selected == null
            ? 'Elegir respuesta'
            : '${_choice(selected).label}. ${_choice(selected).text}',
      ),
    );
  }

  Widget _item(
    BuildContext context,
    BookletItem item, {
    bool showOptions = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.number}. ${item.prompt}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (item.imageUrl case final image?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: AcademicImage(
              value: image,
              label: 'Imagen de la pregunta ${item.number}',
              maxImageHeight: 360,
            ),
          ),
        if (showOptions)
          for (final id in item.choiceIds)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: Key('booklet-choice-${item.id}-$id'),
                  style: selections[item.id] == id
                      ? OutlinedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                        )
                      : null,
                  onPressed: locked ? null : () => onSelect(item.id, id),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_choice(id).label}. ${_choice(id).text}'),
                        if (_choice(id).imageUrl case final image?)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AcademicImage(
                              value: image,
                              label: 'Imagen de la opción ${_choice(id).label}',
                              maxImageHeight: 220,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
        else
          _answer(context, item),
        if (feedback[item.id] case final message?)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
      ],
    ),
  );

  Widget _bank(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palabras', style: Theme.of(context).textTheme.titleMedium),
          for (final choice in activity.choices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${choice.label}. ${choice.text}'),
                  if (choice.imageUrl case final image?)
                    AcademicImage(
                      value: image,
                      label: 'Imagen de la opción ${choice.label}',
                      maxImageHeight: 160,
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _passage(BuildContext context) {
    final passage = activity.passage ?? '';
    if (activity.format != BookletActivityFormat.gapFill) {
      return SelectableText(
        passage,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    final spans = <InlineSpan>[];
    var end = 0;
    for (final match in RegExp(r'\{\{(\d+)\}\}').allMatches(passage)) {
      spans.add(TextSpan(text: passage.substring(end, match.start)));
      final number = int.parse(match[1]!);
      final item = activity.items.firstWhere((item) => item.number == number);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: TextButton(
              onPressed: locked ? null : () => _choose(context, item),
              child: Text(
                '($number) ${selections[item.id] == null ? '______' : _choice(selections[item.id]!).text}',
              ),
            ),
          ),
        ),
      );
      end = match.end;
    }
    spans.add(TextSpan(text: passage.substring(end)));
    return Text.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(activity.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text(activity.instructions),
      if (activity.imageUrl case final image?)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AcademicImage(
            value: image,
            label: 'Imagen del contexto compartido',
            maxImageHeight: 400,
          ),
        ),
      if (activity.example case final example?)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Ejemplo\n${example.prompt}\nRespuesta: ${example.answer}',
          ),
        ),
      if (activity.passage?.isNotEmpty ?? false)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _passage(context),
          ),
        ),
      if (activity.format == BookletActivityFormat.vocabularyMatching)
        LayoutBuilder(
          builder: (context, constraints) {
            final descriptions = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descripciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final item in activity.items) _item(context, item),
              ],
            );
            if (constraints.maxWidth >= 340 &&
                MediaQuery.textScalerOf(context).scale(1) < 1.5) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: descriptions),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _bank(context)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_bank(context), descriptions],
            );
          },
        )
      else
        for (final item in activity.items)
          _item(context, item, showOptions: true),
      if (activity.source.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            activity.source,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/practice_models.dart';

class OfficialSimulationPage extends StatelessWidget {
  const OfficialSimulationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Simulacro 150 · AM/PM')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Dos jornadas, una prueba completa',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Resuelve 150 preguntas distribuidas en dos jornadas protegidas de 75 preguntas. Cada jornada incluye las cinco áreas y se guarda por separado.',
        ),
        const SizedBox(height: 16),
        const _FormatSummary(),
        const SizedBox(height: 22),
        Text(
          'Elige una jornada',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final block in OfficialSimulationBlock.values) ...[
          Card(
            child: ListTile(
              key: Key('start-official-${block.slug}'),
              leading: CircleAvatar(
                child: Icon(
                  block == OfficialSimulationBlock.morning
                      ? Icons.wb_sunny_outlined
                      : Icons.nights_stay_outlined,
                ),
              ),
              title: Text(block.label),
              subtitle: Text(
                '${block.description} · ${OfficialSimulationBlock.questionCount} preguntas',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(block.routeLocation),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Las respuestas correctas y explicaciones permanecen protegidas hasta finalizar cada jornada. Puedes reanudar un intento vigente desde este dispositivo.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Este formato usa el banco autorizado de SaberPlus. No incluye ni descarga cuadernillos oficiales de terceros.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _FormatSummary extends StatelessWidget {
  const _FormatSummary();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: _SummaryValue(value: '150', label: 'preguntas'),
              ),
              SizedBox(height: 44, child: VerticalDivider()),
              Expanded(
                child: _SummaryValue(value: '2', label: 'jornadas'),
              ),
              SizedBox(height: 44, child: VerticalDivider()),
              Expanded(
                child: _SummaryValue(value: '5', label: 'áreas'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Cada intento dispone del tiempo protegido admitido por la API y reserva cinco minutos para un envío seguro.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}

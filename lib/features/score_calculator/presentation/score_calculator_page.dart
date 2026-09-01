import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/icfes_score_calculator.dart';

class ScoreCalculatorPage extends StatefulWidget {
  const ScoreCalculatorPage({super.key});

  @override
  State<ScoreCalculatorPage> createState() => _ScoreCalculatorPageState();
}

class _ScoreCalculatorPageState extends State<ScoreCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _criticalReading = TextEditingController();
  final _mathematics = TextEditingController();
  final _socialSciences = TextEditingController();
  final _naturalSciences = TextEditingController();
  final _english = TextEditingController();
  int? _result;

  @override
  void dispose() {
    _criticalReading.dispose();
    _mathematics.dispose();
    _socialSciences.dispose();
    _naturalSciences.dispose();
    _english.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calculadora de puntaje')),
    body: Form(
      key: _formKey,
      child: ListView(
        key: const Key('score-calculator-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calculate_outlined, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'Calcula tu puntaje global',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingresa los cinco puntajes por prueba, cada uno entre 0 y 100.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _FormulaCard(),
          const SizedBox(height: 16),
          _ScoreField(
            key: const Key('score-critical-reading'),
            controller: _criticalReading,
            label: 'Lectura Crítica',
            weight: 3,
            onChanged: _clearResult,
          ),
          _ScoreField(
            key: const Key('score-mathematics'),
            controller: _mathematics,
            label: 'Matemáticas',
            weight: 3,
            onChanged: _clearResult,
          ),
          _ScoreField(
            key: const Key('score-social-sciences'),
            controller: _socialSciences,
            label: 'Sociales y Ciudadanas',
            weight: 3,
            onChanged: _clearResult,
          ),
          _ScoreField(
            key: const Key('score-natural-sciences'),
            controller: _naturalSciences,
            label: 'Ciencias Naturales',
            weight: 3,
            onChanged: _clearResult,
          ),
          _ScoreField(
            key: const Key('score-english'),
            controller: _english,
            label: 'Inglés',
            weight: 1,
            onChanged: _clearResult,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('calculate-global-score'),
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Calcular puntaje'),
          ),
          TextButton(
            key: const Key('clear-score-calculator'),
            onPressed: _clear,
            child: const Text('Restablecer'),
          ),
          if (_result case final result?) ...[
            const SizedBox(height: 12),
            Card(
              key: const Key('global-score-result'),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Text('Puntaje global calculado'),
                    const SizedBox(height: 6),
                    Text(
                      '$result',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Text('de 500'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El cálculo no se guarda ni reemplaza el resultado oficial. Usa puntajes por prueba; la calculadora no convierte respuestas correctas en puntajes ICFES.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final scores = IcfesAreaScores(
      criticalReading: int.parse(_criticalReading.text),
      mathematics: int.parse(_mathematics.text),
      socialSciences: int.parse(_socialSciences.text),
      naturalSciences: int.parse(_naturalSciences.text),
      english: int.parse(_english.text),
    );
    setState(() => _result = IcfesScoreCalculator.globalScore(scores));
  }

  void _clearResult(String _) {
    if (_result != null) setState(() => _result = null);
  }

  void _clear() {
    _formKey.currentState?.reset();
    _criticalReading.clear();
    _mathematics.clear();
    _socialSciences.clear();
    _naturalSciences.clear();
    _english.clear();
    setState(() => _result = null);
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fórmula', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('(3LC + 3M + 3SC + 3CN + I) ÷ 13 × 5'),
          const SizedBox(height: 4),
          const Text(
            'Lectura, Matemáticas, Sociales y Ciencias pesan 3. Inglés pesa 1.',
          ),
        ],
      ),
    ),
  );
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    super.key,
    required this.controller,
    required this.label,
    required this.weight,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int weight;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Peso $weight',
        hintText: '0–100',
        suffixText: '/ 100',
      ),
      onChanged: onChanged,
      validator: (value) {
        final score = int.tryParse(value ?? '');
        if (score == null || score < 0 || score > 100) {
          return 'Escribe un número entero entre 0 y 100.';
        }
        return null;
      },
    ),
  );
}

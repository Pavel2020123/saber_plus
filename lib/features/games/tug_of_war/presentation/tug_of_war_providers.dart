import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tug_of_war_models.dart';

typedef TugCpuPlanner = TugCpuTurn Function(TugCpuDifficulty difficulty);

final tugCpuPlannerProvider = Provider<TugCpuPlanner>((ref) {
  final random = Random();
  return (difficulty) => TugCpuTurn.random(difficulty, random);
});

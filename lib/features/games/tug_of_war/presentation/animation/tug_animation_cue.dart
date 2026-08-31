import '../../domain/tug_of_war_models.dart';

enum TugArenaSoundCue { ropeStrain, pull }

class TugAnimationCue {
  const TugAnimationCue({
    required this.id,
    required this.fromPosition,
    required this.toPosition,
    required this.outcome,
    required this.bothCorrect,
    this.winner,
  });

  final int id;
  final int fromPosition;
  final int toPosition;
  final TugRoundOutcome outcome;
  final bool bothCorrect;
  final TugWinner? winner;

  int get ropeDelta => toPosition - fromPosition;
  bool get isStrongPull =>
      outcome == TugRoundOutcome.strongPlayer ||
      outcome == TugRoundOutcome.strongCpu;
  bool get isQuickPull =>
      outcome == TugRoundOutcome.quickPlayer ||
      outcome == TugRoundOutcome.quickCpu;
  bool get isNeutral => ropeDelta == 0;
  bool get isSpeedTie => isNeutral && bothCorrect;

  Duration get actionDuration => switch (outcome) {
    TugRoundOutcome.strongPlayer ||
    TugRoundOutcome.strongCpu => const Duration(milliseconds: 980),
    TugRoundOutcome.quickPlayer ||
    TugRoundOutcome.quickCpu => const Duration(milliseconds: 760),
    _ when bothCorrect => const Duration(milliseconds: 720),
    _ => const Duration(milliseconds: 500),
  };

  Duration get duration => winner == null
      ? actionDuration
      : actionDuration + const Duration(milliseconds: 900);
}

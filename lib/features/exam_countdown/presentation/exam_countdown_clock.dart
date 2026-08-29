import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ExamCountdownNow = DateTime Function();

final examCountdownNowProvider = Provider<ExamCountdownNow>(
  (ref) => DateTime.now,
);

final examCountdownClockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final now = ref.watch(examCountdownNowProvider);
  Timer? timer;
  late final StreamController<DateTime> controller;

  void emitAndSchedule() {
    final current = now();
    if (!controller.isClosed) controller.add(current);
    final nextDay = DateTime(
      current.year,
      current.month,
      current.day + 1,
    ).add(const Duration(seconds: 1));
    final delay = nextDay.difference(current);
    timer = Timer(delay.isNegative ? const Duration(seconds: 1) : delay, () {
      if (!controller.isClosed) emitAndSchedule();
    });
  }

  controller = StreamController<DateTime>(
    onListen: emitAndSchedule,
    onCancel: () => timer?.cancel(),
  );
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});

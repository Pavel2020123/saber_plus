import 'dart:async';

import 'package:flutter/material.dart';

class StudyBreakReminder extends StatefulWidget {
  const StudyBreakReminder({
    super.key,
    required this.child,
    this.enabled = true,
    this.reminderAfter = const Duration(minutes: 50),
    this.breakDuration = const Duration(minutes: 3),
    this.onPromptOpening,
    this.onPromptClosed,
  });

  final Widget child;
  final bool enabled;
  final Duration reminderAfter;
  final Duration breakDuration;
  final VoidCallback? onPromptOpening;
  final VoidCallback? onPromptClosed;

  @override
  State<StudyBreakReminder> createState() => _StudyBreakReminderState();
}

class _StudyBreakReminderState extends State<StudyBreakReminder>
    with WidgetsBindingObserver {
  Timer? _timer;
  var _activeSeconds = 0;
  var _foreground = true;
  var _promptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant StudyBreakReminder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      _activeSeconds = 0;
      _promptShown = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  void _tick() {
    if (!mounted || !widget.enabled || !_foreground || _promptShown) return;
    _activeSeconds += 1;
    if (_activeSeconds >= widget.reminderAfter.inSeconds) {
      _promptShown = true;
      unawaited(_showPrompt());
    }
  }

  Future<void> _showPrompt() async {
    widget.onPromptOpening?.call();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StudyBreakDialog(duration: widget.breakDuration),
    );
    if (!mounted) return;
    widget.onPromptClosed?.call();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class StudyBreakDialog extends StatefulWidget {
  const StudyBreakDialog({
    super.key,
    this.duration = const Duration(minutes: 3),
  });

  final Duration duration;

  @override
  State<StudyBreakDialog> createState() => _StudyBreakDialogState();
}

class _StudyBreakDialogState extends State<StudyBreakDialog> {
  Timer? _timer;
  var _started = false;
  var _remainingSeconds = 0;

  void _startBreak() {
    setState(() {
      _started = true;
      _remainingSeconds = widget.duration.inSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        Navigator.pop(context);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('study-break-dialog'),
    icon: Icon(_started ? Icons.self_improvement_rounded : Icons.water_drop),
    title: Text(_started ? 'Tu descanso está en curso' : '¿Y si descansas?'),
    content: _started
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatBreakDuration(_remainingSeconds),
                key: const Key('study-break-countdown'),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Camina un poco, toma agua y descansa la vista. Aquí te esperamos.',
                textAlign: TextAlign.center,
              ),
            ],
          )
        : const Text(
            'Llevas bastante tiempo concentrado. Ve, camina, toma agua, despeja la mente y vuelve en tres minutos.',
          ),
    actions: _started
        ? [
            TextButton(
              key: const Key('finish-study-break-early'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver antes'),
            ),
          ]
        : [
            TextButton(
              key: const Key('skip-study-break'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              key: const Key('start-study-break'),
              onPressed: _startBreak,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Descansar 3 minutos'),
            ),
          ],
  );
}

String formatBreakDuration(int totalSeconds) {
  final safeSeconds = totalSeconds.clamp(0, 3599);
  final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

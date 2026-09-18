import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../trivia_rush/presentation/game_scene_motion.dart';
import 'ghost_character.dart';
import 'sabi_runner_painter.dart';

/// Isolated art review: no repositories, scores, rewards or network access.
class SabiChasePreviewPage extends StatefulWidget {
  const SabiChasePreviewPage({super.key});

  @override
  State<SabiChasePreviewPage> createState() => _SabiChasePreviewPageState();
}

class _SabiChasePreviewPageState extends State<SabiChasePreviewPage> {
  bool _playing = true;
  double _pose = .15;
  double _lastPhase = .15;
  double _rawPhase = 0;
  double _phaseOffset = 0;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sabi · prueba de carrera')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Un personaje, un movimiento continuo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Muestra visual G-SABI-1B. No es una partida: no cambia puntos, récords ni recompensas.',
          ),
          const SizedBox(height: 20),
          Semantics(
            image: true,
            label:
                'Sabi corre detrás de un fantasma. Vista previa sin resultado de juego.',
            child: RepaintBoundary(
              key: const Key('sabi-chase-preview'),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TickerMode(
                    enabled:
                        _playing &&
                        !reduced &&
                        TickerMode.valuesOf(context).enabled,
                    child: GameSceneMotion(
                      duration: const Duration(milliseconds: 900),
                      builder: (context, phase) {
                        _rawPhase = phase;
                        final current = reduced
                            ? .15
                            : (_playing ? (phase + _phaseOffset) % 1 : _pose);
                        _lastPhase = current;
                        return CustomPaint(
                          painter: SabiChasePainter(
                            phase: current,
                            dark:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (reduced)
            const Text('Movimiento reducido activado: mostramos una pose fija.')
          else ...[
            FilledButton.icon(
              key: const Key('sabi-motion-toggle'),
              onPressed: () => setState(() {
                if (_playing) {
                  _pose = _lastPhase;
                } else {
                  _phaseOffset = (_pose - _rawPhase + 1) % 1;
                }
                _playing = !_playing;
              }),
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_playing ? 'Pausar carrera' : 'Reproducir carrera'),
            ),
            const SizedBox(height: 12),
            const Text('Pausa para revisar las poses del ciclo'),
            Slider(
              key: const Key('sabi-pose-slider'),
              value: _pose,
              semanticFormatterCallback: (value) =>
                  'Pose ${(value * 100).round()} por ciento',
              onChanged: _playing
                  ? null
                  : (value) => setState(() => _pose = value),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Adaptación vectorial inicial basada en tu imagen. Revisaremos el parecido antes de crear la captura y la celebración.',
          ),
        ],
      ),
    );
  }
}

class SabiChasePainter extends CustomPainter {
  const SabiChasePainter({required this.phase, required this.dark});
  final double phase;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 480, size.height / 320);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 480, 320),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [const Color(0xff18283b), const Color(0xff273344)]
              : [const Color(0xffeaf8ff), const Color(0xfffcfaff)],
        ).createShader(const Rect.fromLTWH(0, 0, 480, 320)),
    );
    // A periodic tiled track: phase=0 and phase=1 paint the same scene.
    final ground = Paint()
      ..color = dark ? const Color(0xff435b68) : const Color(0xffcfe4e7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 259, 480, 61),
        const Radius.circular(0),
      ),
      ground,
    );
    for (var i = -1; i < 9; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 72 - phase * 72, 288, 28, 3),
          const Radius.circular(2),
        ),
        Paint()
          ..color = dark ? const Color(0xff78939e) : const Color(0xffa7c9d0),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(94, 251, 106, 12),
      Paint()..color = const Color(0xff153d59).withValues(alpha: .12),
    );
    canvas.save();
    canvas.translate(50, 20);
    SabiRunnerPainter(phase: phase).paint(canvas, const Size(200, 250));
    canvas.restore();
    canvas.save();
    canvas.translate(286 + math.sin(phase * math.pi * 2) * 3, 92);
    GhostCharacterPainter(
      phase: phase,
      mood: GhostMood.friendly,
      forming: false,
    ).paint(canvas, const Size(132, 132));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(SabiChasePainter oldDelegate) =>
      phase != oldDelegate.phase || dark != oldDelegate.dark;
}

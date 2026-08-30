import 'dart:async';
import 'package:flutter/material.dart';

/// Live-updating time display, ticking once per second. Used on Live Group
/// Status Screen, Alarm Ringing Screen, and resend-email cooldowns.
///
/// Pass [targetTime] to count down to a future moment, or leave it null
/// with [startTime] set to count elapsed time upward instead.
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    this.targetTime,
    this.startTime,
    this.style,
  }) : assert(targetTime != null || startTime != null,
            'Provide either targetTime (countdown) or startTime (elapsed)');

  final DateTime? targetTime;
  final DateTime? startTime;
  final TextStyle? style;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    setState(() {
      _duration = widget.targetTime != null
          ? widget.targetTime!.difference(now)
          : now.difference(widget.startTime!);
    });
  }

  String _format(Duration d) {
    final neg = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    final s = abs.inSeconds.remainder(60);
    final base = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return neg ? '-$base' : base;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_format(_duration), style: widget.style ?? Theme.of(context).textTheme.bodyMedium);
  }
}

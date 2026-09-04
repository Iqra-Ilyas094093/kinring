import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../../viewmodels/event_status_viewmodel.dart';
import '../../widgets/common/color_swatch_button.dart';
import '../../widgets/common/progress_dots.dart';
import '../../widgets/feedback/app_toast.dart';
import 'task_cleared_confirmation_screen.dart';

/// The fixed swatch pool the sequence and answer grid are drawn from —
/// reuses existing brand/state colors rather than introducing new hex
/// values (see [AppColors] file-header rule).
const _palette = <Color>[
  AppColors.primary,
  AppColors.secondary,
  AppColors.success,
  AppColors.warning,
  AppColors.error,
  AppColors.accentGold,
];

/// One fixed glyph per palette color, same order — Accessibility
/// Settings' "Colorblind pattern mode" (Phase 10) renders these over
/// each swatch instead of relying on hue alone.
const _patternIcons = <IconData>[
  Icons.circle,
  Icons.square_rounded,
  Icons.change_history_rounded,
  Icons.star_rounded,
  Icons.diamond_rounded,
  Icons.close_rounded,
];

/// Color Match Task Screen (product doc 5.8.2). Verified entirely
/// on-device — no network call needed to clear it, so it keeps working
/// even if the phone is offline (per Part 3, step 4). Sequence length
/// grows with [snoozeCount], matching "difficulty increases with each
/// snooze".
class ColorMatchTaskScreen extends StatefulWidget {
  const ColorMatchTaskScreen({
    super.key,
    required this.draft,
    required this.startedAt,
    this.snoozeCount = 0,
  });

  final EventDraft draft;
  final DateTime startedAt;
  final int snoozeCount;

  @override
  State<ColorMatchTaskScreen> createState() => _ColorMatchTaskScreenState();
}

enum _Phase { preview, input }

class _ColorMatchTaskScreenState extends State<ColorMatchTaskScreen> {
  final _random = Random();
  late int _sequenceLength = (3 + widget.snoozeCount).clamp(3, 6);
  late List<Color> _sequence = _generateSequence();
  int _previewIndex = -1;
  int _inputProgress = 0;
  int _round = 1;
  _Phase _phase = _Phase.preview;
  Timer? _previewTimer;
  late List<Color> _answerGrid = _shuffledPalette();
  bool _colorblindMode = false;

  IconData? _patternFor(Color color) =>
      _colorblindMode ? _patternIcons[_palette.indexOf(color)] : null;

  List<Color> _shuffledPalette() => List<Color>.from(_palette)..shuffle(_random);

  List<Color> _generateSequence() =>
      List.generate(_sequenceLength, (_) => _palette[_random.nextInt(_palette.length)]);

  @override
  void initState() {
    super.initState();
    _startPreview();
    _loadColorblindMode();
  }

  Future<void> _loadColorblindMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _colorblindMode = prefs.getBool('a11y_colorblind_mode') ?? false);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _startPreview() {
    _phase = _Phase.preview;
    _inputProgress = 0;
    _previewIndex = -1;
    _answerGrid = _shuffledPalette();
    var step = 0;
    final totalSteps = _sequence.length * 2; // each color = one "show" tick + one "blank" tick

    _previewTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      if (step >= totalSteps) {
        timer.cancel();
        setState(() => _phase = _Phase.input);
        return;
      }
      setState(() {
        // Alternate: show swatch (even step), then blank it (odd step).
        _previewIndex = step.isEven ? step ~/ 2 : -1;
      });
      step++;
    });
  }

  void _handleSwatchTap(Color color) {
    if (_phase != _Phase.input) return;

    if (color == _sequence[_inputProgress]) {
      setState(() => _inputProgress++);
      if (_inputProgress == _sequence.length) {
        // Phase 8: fire-and-forget — the write shouldn't block the
        // confirmation animation, and a transient failure here isn't
        // worth blocking the user's device from unlocking over.
        EventStatusViewModel().markCleared(groupId: widget.draft.groupId, eventId: widget.draft.eventId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskClearedConfirmationScreen(
              draft: widget.draft,
              startedAt: widget.startedAt,
            ),
          ),
        );
      }
    } else {
      AppToast.show(context, 'Wrong sequence, try again', type: AppToastType.error);
      setState(() {
        _round++;
        _sequence = _generateSequence();
      });
      _startPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('Round $_round', style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _phase == _Phase.preview ? 'Watch the sequence' : 'Repeat the sequence',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 90,
                  child: Center(
                    child: _previewIndex >= 0
                        ? ColorSwatchButton(
                            key: ValueKey(_previewIndex),
                            color: _sequence[_previewIndex],
                            active: true,
                            size: 84,
                            patternIcon: _patternFor(_sequence[_previewIndex]),
                          )
                        : const SizedBox(width: 84, height: 84),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ProgressDots(total: _sequence.length, filled: _inputProgress),
                const Spacer(),
                if (_phase == _Phase.input)
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final color in _answerGrid)
                        ColorSwatchButton(
                          color: color,
                          onTap: () => _handleSwatchTap(color),
                          patternIcon: _patternFor(color),
                        ),
                    ],
                  )
                else
                  Text(
                    'Memorize the flashing order…',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

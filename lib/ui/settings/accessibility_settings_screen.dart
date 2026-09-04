import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/toggle_row.dart';

/// Accessibility Settings screen (product doc 5.10.3). Single colorblind
/// pattern-mode toggle with a before/after preview of the Color Match
/// task's swatches, so users can see the effect before turning it on.
///
/// Phase 10: persisted to `shared_preferences` AND threaded through to
/// the Color Match Task Screen (5.8.2) — that screen reads the same
/// `a11y_colorblind_mode` key on init and renders a fixed glyph over
/// each swatch when it's on.
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  static const _kColorblindMode = 'a11y_colorblind_mode';

  bool _loaded = false;
  bool _colorblindMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _colorblindMode = prefs.getBool(_kColorblindMode) ?? false;
      _loaded = true;
    });
  }

  Future<void> _setColorblindMode(bool value) async {
    setState(() => _colorblindMode = value);
    (await SharedPreferences.getInstance()).setBool(_kColorblindMode, value);
  }

  static const _swatchColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
    AppColors.warning,
  ];
  static const _swatchPatterns = [
    Icons.circle,
    Icons.change_history,
    Icons.square,
    Icons.star,
  ];

  Widget _swatchRow(bool withPattern) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(_swatchColors.length, (i) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _swatchColors[i],
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: withPattern
              ? Icon(_swatchPatterns[i], color: AppColors.white, size: 20)
              : null,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Accessibility')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ToggleRow(
              label: 'Colorblind pattern mode',
              subtitle: 'Adds a shape to each color in the Color Match task',
              value: _colorblindMode,
              onChanged: _setColorblindMode,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Preview', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.light1,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: _swatchRow(_colorblindMode),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _colorblindMode
                  ? 'Each color also shows a distinct shape.'
                  : 'Colors only — no shape markers.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

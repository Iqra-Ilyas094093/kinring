import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/common/list_row.dart';
import '../../widgets/common/note_text.dart';
import '../../widgets/feedback/app_toast.dart';

/// About/Help screen (product doc 5.10.4). App version, expandable FAQ,
/// Contact Support, and Terms/Privacy links.
class AboutHelpScreen extends StatelessWidget {
  const AboutHelpScreen({super.key});

  static const _faqs = [
    (
      q: 'Why does the alarm still ring on my phone?',
      a: 'A group alarm keeps ringing on your device until you clear the '
          'task yourself — it does not stop just because another member '
          'cleared theirs.',
    ),
    (
      q: 'What happens if I snooze?',
      a: 'Snoozing increases the Color Match task difficulty on the next '
          'ring, so repeated snoozing gets progressively harder to clear.',
    ),
    (
      q: 'Can I use KinRing without a group?',
      a: 'Every alarm and reminder belongs to a group. Create a group '
          'with just yourself in it if you want a solo alarm.',
    ),
    (
      q: 'Does "Ring Now" work if my phone is on silent?',
      a: 'Yes — an admin\'s "Ring Now" broadcast bypasses silent mode so '
          'it reaches every member immediately.',
    ),
  ];

  // TODO: add url_launcher to pubspec.yaml and swap this for a real
  // mailto:/https: launch once that dependency is added.
  void _launch(BuildContext context, String label) {
    AppToast.show(context, 'Would open: $label');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('About & Help')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Column(
                children: [
                  Text('KinRing', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Version 1.0.0 (MVP)', style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('FAQ', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ..._faqs.map(
              (faq) => Theme(
                data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(faq.q, style: textTheme.bodyLarge),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: NoteText(text: faq.a, icon: Icons.info_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListRow(
              label: 'Contact Support',
              leading: const Icon(Icons.support_agent_outlined, color: AppColors.dark1),
              onTap: () => _launch(context, 'Contact Support'),
            ),
            ListRow(
              label: 'Terms of Service',
              leading: const Icon(Icons.description_outlined, color: AppColors.dark1),
              onTap: () => _launch(context, 'Terms of Service'),
            ),
            ListRow(
              label: 'Privacy Policy',
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.dark1),
              onTap: () => _launch(context, 'Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
}

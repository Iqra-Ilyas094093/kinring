import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'group_details_screen.dart';

/// Join Group screen (product doc 5.6.2). Invite code entry (or QR scan),
/// a live preview of the matched group once the code is valid, then Join.
///
/// TODO: wire code lookup + join call to a GroupsViewModel; the preview
/// below is demo-only and fakes a match for any 6+ char code.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();

  String? get _matchedGroupName {
    final code = _codeController.text.trim();
    return code.length >= 6 ? 'Gym Crew' : null;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matched = _matchedGroupName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Join a Group')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Invite code',
                controller: _codeController,
                hintText: 'e.g. KR-7F3A2',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: open device camera for QR scan (mobile_scanner
                  // or similar package not yet in pubspec.yaml).
                  AppToast.show(context, 'QR scanning coming soon');
                },
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                label: const Text('Scan QR Code'),
              ),
              if (matched != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Group found', style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.light1,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(name: matched, size: 40),
                      const SizedBox(width: AppSpacing.sm),
                      Text(matched, style: textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Join',
                onPressed: matched != null
                    ? () {
                        // TODO: call GroupsViewModel.joinGroup(code).
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => GroupDetailsScreen(groupName: matched),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

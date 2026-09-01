import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/invite_code_box.dart';
import '../../widgets/feedback/app_toast.dart';

/// Invite Members screen (product doc 5.6.4). Large invite code, copy,
/// QR code, and a share-link action.
///
/// TODO: qr code image needs a package (e.g. qr_flutter) added to
/// pubspec.yaml — shown as a placeholder box until then. Share Link
/// needs package:share_plus, also not yet a dependency.
class InviteMembersScreen extends StatelessWidget {
  const InviteMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
  });

  final String groupId;
  final String groupName;
  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Invite to $groupName')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                'Share this code or QR so others can join',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              InviteCodeBox(code: inviteCode),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.light1,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_2, size: 96, color: AppColors.dark2),
              ),
              const Spacer(),
              SecondaryButton(
                label: 'Share Link',
                onPressed: () {
                  // TODO: package:share_plus Share.share(...).
                  AppToast.show(context, 'Share sheet not wired yet');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

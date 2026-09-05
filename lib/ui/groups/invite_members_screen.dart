import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/common/invite_code_box.dart';
import '../../widgets/feedback/app_toast.dart';

/// Invite Members screen (product doc 5.6.4). Large invite code, copy,
/// QR code, and a share-link action.
///
/// QR (via `qr_flutter`) encodes the invite code as plain text — the
/// same string [JoinGroupScreen]'s QR scanner reads back and drops
/// straight into its code field, so scanning and typing converge on the
/// exact same join path.
///
/// TODO: Share Link needs package:share_plus, not yet a dependency.
class InviteMembersScreen extends StatelessWidget {
  const InviteMembersScreen({
    super.key,
    required this.groupName,
    required this.inviteCode,
  });

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
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: inviteCode,
                  version: QrVersions.auto,
                  backgroundColor: AppColors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.dark1),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.dark1,
                  ),
                ),
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

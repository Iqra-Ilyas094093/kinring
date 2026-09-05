import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../feedback/app_toast.dart';

/// Large invite-code text with a copy button. Used on Invite Members
/// Screen and as the code preview on Join Group Screen.
class InviteCodeBox extends StatelessWidget {
  const InviteCodeBox({
    super.key,
    required this.code,
    this.showCopyButton = true,
  });

  final String code;
  final bool showCopyButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.light1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            code,
            style: textTheme.headlineMedium?.copyWith(letterSpacing: 4),
          ),
          if (showCopyButton)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  AppToast.show(context, 'Invite code copied', type: AppToastType.success);
                }
              },
            ),
        ],
      ),
    );
  }
}

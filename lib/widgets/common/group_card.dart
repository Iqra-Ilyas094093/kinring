import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_avatar.dart';
import 'avatar_stack.dart';

/// Group photo/icon, name, member count, avatar stack, and a next-event
/// preview line. Used on Home ("Your Groups" horizontal scroll) and the
/// Groups Screen (vertical list).
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.groupName,
    required this.memberNames,
    this.memberPhotoUrls,
    this.nextEventLabel,
    this.photoUrl,
    this.onTap,
    this.width,
  });

  final String groupName;
  final List<String> memberNames;

  /// Same length/order as [memberNames] — see [AvatarStack.photoUrls].
  final List<String?>? memberPhotoUrls;
  final String? nextEventLabel;
  final String? photoUrl;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AppAvatar(imageUrl: photoUrl, name: groupName, size: 36),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    groupName,
                    style: textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AvatarStack(names: memberNames, photoUrls: memberPhotoUrls, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Text('${memberNames.length} members', style: textTheme.bodySmall),
              ],
            ),
            if (nextEventLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                nextEventLabel!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.headingPurple),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

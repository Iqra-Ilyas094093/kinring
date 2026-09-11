import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_avatar.dart';

/// One row on the Chat tab's group list (product doc Part 15.1) — group
/// photo, name, last-message preview, and a relative timestamp. Reuses
/// [AppAvatar], same as [GroupCard] does, for visual consistency with
/// the rest of the app rather than introducing a second avatar style.
class ChatPreviewRow extends StatelessWidget {
  const ChatPreviewRow({
    super.key,
    required this.groupName,
    this.photoUrl,
    this.lastMessageText,
    this.lastMessageIsMine = false,
    this.timeLabel,
    this.onTap,
  });

  final String groupName;
  final String? photoUrl;
  final String? lastMessageText;
  final bool lastMessageIsMine;
  final String? timeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preview = lastMessageText == null || lastMessageText!.isEmpty
        ? 'No messages yet'
        : (lastMessageIsMine ? 'You: ${lastMessageText!}' : lastMessageText!);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppAvatar(imageUrl: photoUrl, name: groupName, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupName, style: textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.dark2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (timeLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(timeLabel!, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

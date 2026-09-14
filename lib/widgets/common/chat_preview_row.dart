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
    this.unreadCount = 0,
    this.onTap,
  });

  final String groupName;
  final String? photoUrl;
  final String? lastMessageText;
  final bool lastMessageIsMine;
  final String? timeLabel;

  /// Shown as a small pill on the right, same [Badge] widget already
  /// used for the Home tab's notification bell — 0 renders nothing.
  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preview = lastMessageText == null || lastMessageText!.isEmpty
        ? 'No messages yet'
        : (lastMessageIsMine ? 'You: ${lastMessageText!}' : lastMessageText!);
    final hasUnread = unreadCount > 0;

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
                    style: textTheme.bodyMedium?.copyWith(
                      color: hasUnread ? AppColors.dark1 : AppColors.dark2,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timeLabel != null) Text(timeLabel!, style: textTheme.bodySmall),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

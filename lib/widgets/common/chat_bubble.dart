import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A single message bubble in [GroupChatScreen]'s message list.
/// Text-only (product doc Part 15.1) — no attachment/reaction/edit
/// affordances by design.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.senderName,
    this.time,
  });

  final String text;
  final bool isMine;

  /// Shown above the bubble for other people's messages in a group
  /// thread (there's no 1:1 chat here — every thread is a group, so the
  /// sender needs naming, unlike a typical 2-person chat bubble).
  final String? senderName;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bubbleColor = isMine ? AppColors.primary : AppColors.white;
    final textColor = isMine ? AppColors.white : AppColors.dark1;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine && senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 2),
                child: Text(
                  senderName!,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.headingPurple),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusMd),
                  topRight: const Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(isMine ? AppSpacing.radiusMd : 2),
                  bottomRight: Radius.circular(isMine ? 2 : AppSpacing.radiusMd),
                ),
                border: isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Text(text, style: textTheme.bodyLarge?.copyWith(color: textColor)),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(time!, style: textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

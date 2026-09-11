import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/relative_time.dart';
import '../../models/group_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/common/chat_preview_row.dart';
import '../../widgets/common/empty_state.dart';
import 'group_chat_screen.dart';

/// Chat tab (product doc Part 15.1) — 4th bottom-nav tab, between Groups
/// and Settings. Lists every group the user belongs to, same group set
/// as the Groups tab (reuses [GroupsViewModel.listenGroups] — chat
/// membership is exactly group membership, no separate chat-membership
/// concept), each row showing a last-message preview.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupsVm = context.read<GroupsViewModel>();
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Text('Chat', style: textTheme.headlineLarge),
            ),
            Expanded(
              child: StreamBuilder<List<GroupModel>>(
                stream: groupsVm.listenGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final groups = snapshot.data ?? const <GroupModel>[];
                  if (groups.isEmpty) {
                    return const Center(
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No group chats yet',
                        subtitle: 'Join or create a group to start chatting with your group.',
                      ),
                    );
                  }
                  // Most-recently-active chat first — falls back to
                  // list order for groups with no messages yet.
                  final sorted = [...groups]..sort((a, b) {
                      final at = a.lastMessageAt;
                      final bt = b.lastMessageAt;
                      if (at == null && bt == null) return 0;
                      if (at == null) return 1;
                      if (bt == null) return -1;
                      return bt.compareTo(at);
                    });
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, i) {
                      final group = sorted[i];
                      return ChatPreviewRow(
                        groupName: group.name,
                        photoUrl: group.photoUrl,
                        lastMessageText: group.lastMessageText,
                        lastMessageIsMine: group.lastMessageSenderUid != null && group.lastMessageSenderUid == myUid,
                        timeLabel: group.lastMessageAt != null ? relativeTime(group.lastMessageAt!) : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupChatScreen(groupId: group.id, groupName: group.name, groupPhotoUrl: group.photoUrl),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

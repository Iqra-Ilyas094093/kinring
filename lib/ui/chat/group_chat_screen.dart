import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/relative_time.dart';
import '../../models/chat_message_model.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/chat_bubble.dart';
import '../../widgets/common/empty_state.dart';

/// One group's chat thread (product doc Part 15.1). Every member of the
/// group can send/read here — chat membership is exactly group
/// membership, there's no separate participant list to manage.
///
/// Text-only, permanently: no attachment button, no voice note, no
/// call icon in the app bar — see Part 15.1 for the full out-of-scope
/// list. If any of that is wanted later it's a deliberate new feature,
/// not something accidentally missing here.
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.groupId, required this.groupName, this.groupPhotoUrl});

  final String groupId;
  final String groupName;
  final String? groupPhotoUrl;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _composerController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _send(ChatViewModel chatVm) async {
    final text = _composerController.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _composerController.clear();
    await chatVm.sendMessage(groupId: widget.groupId, text: text);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final chatVm = context.read<ChatViewModel>();
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(imageUrl: widget.groupPhotoUrl, name: widget.groupName, size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(widget.groupName, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: chatVm.listenMessages(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? const <ChatMessageModel>[];
                  if (messages.isEmpty) {
                    return const Center(
                      child: EmptyState(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'No messages yet',
                        subtitle: 'Say hello to the group.',
                      ),
                    );
                  }
                  // listenMessages orders newest-first (Firestore query);
                  // reverse: true on the ListView means index 0 (newest)
                  // renders at the bottom — standard chat layout, no
                  // second in-memory sort needed.
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final message = messages[i];
                      final isMine = message.senderUid == myUid;
                      return ChatBubble(
                        text: message.text,
                        isMine: isMine,
                        senderName: isMine ? null : (message.senderDisplayName ?? 'Member'),
                        time: message.sentAt != null ? relativeTime(message.sentAt!) : null,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composerController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message the group…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusPill))),
                        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      ),
                      onSubmitted: (_) => _send(chatVm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _sending ? null : () => _send(chatVm),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

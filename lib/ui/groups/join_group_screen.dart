import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/group_model.dart';
import '../../viewmodels/groups_viewmodel.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/feedback/app_toast.dart';
import '../../widgets/inputs/app_text_field.dart';
import 'group_details_screen.dart';

/// Join Group screen (product doc 5.6.2). Invite code entry (or QR scan),
/// a live preview of the matched group once the code is valid, then Join.
///
/// Live data: [GroupsViewModel.lookupByCode] (preview) and
/// [GroupsViewModel.joinGroup] (actual join).
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();
  Timer? _debounce;
  GroupModel? _matched;
  bool _looking = false;
  bool _joining = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    _debounce?.cancel();
    setState(() => _matched = null);
    final code = value.trim();
    if (code.length < 6) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _looking = true);
      final group = await context.read<GroupsViewModel>().lookupByCode(code);
      if (!mounted) return;
      setState(() {
        _matched = group;
        _looking = false;
      });
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    final group = await context.read<GroupsViewModel>().joinGroup(_codeController.text.trim());
    if (!mounted) return;
    setState(() => _joining = false);
    if (group == null) {
      AppToast.show(context, 'Could not join — check the invite code.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(groupId: group.id, groupName: group.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                onChanged: _onCodeChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  // QR scanning needs a camera plugin (e.g. mobile_scanner)
                  // not yet in pubspec.yaml — out of scope for MVP per doc.
                  AppToast.show(context, 'QR scanning coming soon');
                },
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                label: const Text('Scan QR Code'),
              ),
              if (_looking) ...[
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator()),
              ],
              if (!_looking && _matched != null) ...[
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
                      AppAvatar(name: _matched!.name, imageUrl: _matched!.photoUrl, size: 40),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_matched!.name, style: textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _joining ? 'Joining…' : 'Join',
                onPressed: _matched != null && !_joining ? _join : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

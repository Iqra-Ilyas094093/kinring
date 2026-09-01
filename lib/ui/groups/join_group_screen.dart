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
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();
  Timer? _debounce;
  Group? _matched;
  bool _looking = false;
  bool _joining = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    setState(() => _matched = null);
    _debounce?.cancel();
    if (value.trim().length < 6) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _looking = true);
      final group = await context.read<GroupsViewModel>().previewGroupByCode(value);
      if (!mounted) return;
      setState(() {
        _matched = group;
        _looking = false;
      });
    });
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      final group = await context.read<GroupsViewModel>().joinGroup(_codeController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GroupDetailsScreen(groupId: group.id, groupName: group.name),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, "Couldn't join group. Try again.", type: AppToastType.error);
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matched = _matched;

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
                  // TODO: open device camera for QR scan (mobile_scanner
                  // or similar package not yet in pubspec.yaml).
                  AppToast.show(context, 'QR scanning coming soon');
                },
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                label: const Text('Scan QR Code'),
              ),
              if (_looking) ...[
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ] else if (matched != null) ...[
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
                      AppAvatar(name: matched.name, imageUrl: matched.photoUrl, size: 40),
                      const SizedBox(width: AppSpacing.sm),
                      Text(matched.name, style: textTheme.titleLarge),
                    ],
                  ),
                ),
              ] else if (_codeController.text.trim().length >= 6) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('No group found for that code.', style: textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Join',
                isLoading: _joining,
                onPressed: matched != null && !_joining ? _join : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

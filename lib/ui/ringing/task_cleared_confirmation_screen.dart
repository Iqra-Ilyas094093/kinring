import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/event_draft.dart';
import '../status/live_group_status_screen.dart';

/// Task Cleared Confirmation (product doc 5.8.3). Shared end-point for
/// both the Color Match and Type & Confirm task screens — a brief
/// checkmark moment that auto-dismisses into the Live Group Status
/// Screen, where the member's status flips from "Ringing"/"Pending" to
/// "Cleared" for the rest of the group to see.
class TaskClearedConfirmationScreen extends StatefulWidget {
  const TaskClearedConfirmationScreen({
    super.key,
    required this.draft,
    required this.startedAt,
  });

  final EventDraft draft;
  final DateTime startedAt;

  @override
  State<TaskClearedConfirmationScreen> createState() => _TaskClearedConfirmationScreenState();
}

class _TaskClearedConfirmationScreenState extends State<TaskClearedConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LiveGroupStatusScreen(
            draft: widget.draft,
            startedAt: widget.startedAt,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 56),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Cleared', style: Theme.of(context).textTheme.headlineLarge),
            ],
          ),
        ),
      ),
    );
  }
}

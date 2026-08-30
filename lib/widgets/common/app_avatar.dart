import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular profile image. Falls back to initials on a light-purple fill
/// when no image is available. Used on Settings, Group Details (member
/// list), Live Status Screen.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  String get _initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.light2,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.light2,
      child: Text(
        _initials,
        style: TextStyle(
          color: AppColors.dark2,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

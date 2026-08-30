import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_avatar.dart';

/// Multiple small overlapping avatars. Used on Home (group cards) and
/// Groups Screen (group cards).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.size = 28,
    this.maxVisible = 4,
  });

  final List<String> names;
  final double size;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(maxVisible).toList();
    final overflow = names.length - visible.length;
    final overlap = size * 0.6;

    return SizedBox(
      height: size,
      width: overlap * (visible.length + (overflow > 0 ? 1 : 0)) + (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.white, width: 2),
                  ),
                ),
                child: AppAvatar(name: visible[i], size: size),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.light2,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.white, width: 2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

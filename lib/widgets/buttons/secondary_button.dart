import 'package:flutter/material.dart';

/// Lower-emphasis outline button.
///
/// Used for: Welcome Screen "Sign Up", cancel-adjacent actions, and any
/// spot where a `PrimaryButton` would compete with a more important action
/// on the same screen.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

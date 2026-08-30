import 'package:flutter/material.dart';

/// Solid, brand-colored full-width button — the app's main call to action.
///
/// Used across: Login, Signup, Forgot Password, Create Group, Join Group,
/// Create Event (all steps), Event Summary, Task screens, Account Settings,
/// and more. Build once, reuse everywhere — never a one-off `ElevatedButton`
/// in a screen file.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}

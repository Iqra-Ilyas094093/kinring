import 'package:flutter/material.dart';

/// Checkbox paired with label text. Used on Signup (terms agreement).
class CheckboxRow extends StatelessWidget {
  const CheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: label),
      ],
    );
  }
}

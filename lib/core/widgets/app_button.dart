import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget child = loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final button = icon != null && !loading
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: child,
          )
        : FilledButton(
            onPressed: loading ? null : onPressed,
            child: child,
          );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

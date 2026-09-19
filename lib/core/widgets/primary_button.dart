import 'package:flutter/material.dart';

/// design.md §7.1: "Primary button — Filled with role accent. Loading
/// state and disabled state." [accentColor] defaults to the current
/// theme's primary but screens should pass their role's accent
/// (AppColors.accentFor(role)) explicitly — see student_home_screen.dart.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? accentColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: disabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

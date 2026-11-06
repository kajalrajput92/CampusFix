import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant { primary, accent, outlined }

/// Reusable branded button supporting Navy primary, Green accent, and Outlined styles.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(context, AppColors.primaryNavy),
      );
    }

    final backgroundColor = variant == AppButtonVariant.accent
        ? AppColors.accentGreen
        : AppColors.primaryNavy;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: backgroundColor),
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(context, Colors.white),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor)),
        ],
      );
    }

    return Text(label, style: TextStyle(color: textColor));
  }
}

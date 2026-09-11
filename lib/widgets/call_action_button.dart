import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isDestructive;
  final bool isDisabled;
  final double size;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
    this.isDestructive = false,
    this.isDisabled = false,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isDisabled ? null : onPressed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: effectiveOnPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _iconColor,
              size: size * 0.4,
              semanticLabel: label,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isDisabled
                ? Colors.white38
                : Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color get _backgroundColor {
    if (isDisabled) return AppColors.callControlBackground.withValues(alpha: 0.5);
    if (isDestructive) return AppColors.callEnd;
    if (isActive) return AppColors.callControlActive;
    return AppColors.callControlBackground;
  }

  Color get _iconColor {
    if (isDisabled) return Colors.white38;
    if (isDestructive) return Colors.white;
    if (isActive) return AppColors.callBackground;
    return Colors.white;
  }
}

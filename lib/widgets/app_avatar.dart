import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'status_indicator.dart';

enum AvatarSize { small, medium, large, extraLarge, call }

class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final AvatarSize size;
  final bool showOnlineStatus;
  final bool isOnline;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AvatarSize.medium,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.backgroundColor,
  });

  double get _radius {
    switch (size) {
      case AvatarSize.small:
        return 20;
      case AvatarSize.medium:
        return 28;
      case AvatarSize.large:
        return 40;
      case AvatarSize.extraLarge:
        return 56;
      case AvatarSize.call:
        return 70;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.small:
        return 14;
      case AvatarSize.medium:
        return 18;
      case AvatarSize.large:
        return 24;
      case AvatarSize.extraLarge:
        return 32;
      case AvatarSize.call:
        return 36;
    }
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight);

    final hasValidImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget avatar = CircleAvatar(
      radius: _radius,
      backgroundColor: bgColor,
      backgroundImage: hasValidImage ? NetworkImage(imageUrl!.trim()) : null,
      onBackgroundImageError: hasValidImage ? (e, s) {} : null,
      child: !hasValidImage
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
    );

    if (!showOnlineStatus) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: StatusIndicator(
            isOnline: isOnline,
            size: size == AvatarSize.small ? 10 : 14,
          ),
        ),
      ],
    );
  }
}

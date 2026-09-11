import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/app_user.dart';
import 'app_avatar.dart';
import '../core/utils/date_utils.dart';

class UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final bool showCallActions;

  const UserTile({
    super.key,
    required this.user,
    this.onTap,
    this.onAudioCall,
    this.onVideoCall,
    this.showCallActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppAvatar(
              name: user.name,
              imageUrl: user.avatarUrl,
              size: AvatarSize.medium,
              showOnlineStatus: true,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.isOnline
                        ? 'Online'
                        : AppDateUtils.formatLastSeen(user.lastSeen),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: user.isOnline
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (showCallActions) ...[
              IconButton(
                onPressed: onAudioCall,
                icon: const Icon(Icons.call_outlined),
                tooltip: 'Audio call',
                iconSize: 22,
              ),
              IconButton(
                onPressed: onVideoCall,
                icon: const Icon(Icons.videocam_outlined),
                tooltip: 'Video call',
                iconSize: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

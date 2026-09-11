import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/app_button.dart';

class ContactDetailView extends StatelessWidget {
  const ContactDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppUser user = Get.arguments as AppUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            // Avatar
            AppAvatar(
              name: user.name,
              imageUrl: user.avatarUrl,
              size: AvatarSize.extraLarge,
              showOnlineStatus: true,
              isOnline: user.isOnline,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              user.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.isOnline
                  ? 'Online'
                  : AppDateUtils.formatLastSeen(user.lastSeen),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: user.isOnline
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Audio Call',
                    icon: Icons.call,
                    onPressed: () => Get.toNamed(
                      AppRoutes.audioCall,
                      arguments: {
                        'receiverId': user.id,
                        'callType': CallType.audio,
                        'user': user,
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Video Call',
                    icon: Icons.videocam,
                    variant: AppButtonVariant.outline,
                    onPressed: () => Get.toNamed(
                      AppRoutes.videoCall,
                      arguments: {
                        'receiverId': user.id,
                        'callType': CallType.video,
                        'user': user,
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.huge),

            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerTheme.color ?? Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Info',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: Icons.circle,
                    label: 'Status',
                    value: user.isOnline ? 'Online' : 'Offline',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

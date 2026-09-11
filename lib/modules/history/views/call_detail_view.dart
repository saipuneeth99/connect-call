import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../data/models/call.dart';
import '../../../data/models/call_status.dart';
import '../../../data/models/app_user.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/app_button.dart';

class CallDetailView extends StatelessWidget {
  const CallDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Call call = Get.arguments as Call;
    final other = call.otherParticipant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),

            // Avatar
            AppAvatar(
              name: other.name,
              imageUrl: other.avatarUrl,
              size: AvatarSize.extraLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Name
            Text(
              other.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Details card
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
                children: [
                  _DetailRow(
                    label: 'Type',
                    value: call.type.label,
                    icon: call.isVideo ? Icons.videocam : Icons.call,
                  ),
                  const Divider(height: AppSpacing.xxl),
                  _DetailRow(
                    label: 'Direction',
                    value: call.direction.label,
                    icon: call.isIncoming
                        ? Icons.call_received
                        : Icons.call_made,
                  ),
                  const Divider(height: AppSpacing.xxl),
                  _DetailRow(
                    label: 'Status',
                    value: call.isMissed
                        ? 'Missed'
                        : call.isRejected
                            ? 'Declined'
                            : 'Completed',
                    icon: call.isMissed
                        ? Icons.call_missed
                        : Icons.check_circle_outline,
                  ),
                  const Divider(height: AppSpacing.xxl),
                  _DetailRow(
                    label: 'Date & Time',
                    value: AppDateUtils.formatDateTime(call.startedAt),
                    icon: Icons.access_time,
                  ),
                  if (call.duration != null) ...[
                    const Divider(height: AppSpacing.xxl),
                    _DetailRow(
                      label: 'Duration',
                      value: DurationUtils.formatShort(call.duration!),
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Call Again',
                    icon: Icons.call,
                    onPressed: () => Get.toNamed(
                      AppRoutes.audioCall,
                      arguments: {
                        'receiverId': other.id,
                        'callType': CallType.audio,
                        'user': AppUser(
                          id: other.id,
                          name: other.name,
                          avatarUrl: other.avatarUrl,
                          email: '',
                          isOnline: true,
                        ),
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
                        'receiverId': other.id,
                        'callType': CallType.video,
                        'user': AppUser(
                          id: other.id,
                          name: other.name,
                          avatarUrl: other.avatarUrl,
                          email: '',
                          isOnline: true,
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

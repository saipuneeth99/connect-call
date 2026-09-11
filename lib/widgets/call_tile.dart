import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/duration_utils.dart';
import '../data/models/call.dart';
import '../data/models/call_status.dart';
import 'app_avatar.dart';

class CallTile extends StatelessWidget {
  final Call call;
  final VoidCallback? onTap;
  final VoidCallback? onCallBack;

  const CallTile({
    super.key,
    required this.call,
    this.onTap,
    this.onCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final other = call.otherParticipant;

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
              name: other.name,
              imageUrl: other.avatarUrl,
              size: AvatarSize.medium,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: call.isMissed ? AppColors.missedCall : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _directionIcon,
                        size: 14,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: call.isMissed
                                ? AppColors.missedCall
                                : theme.textTheme.bodySmall?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppDateUtils.formatCallTimestamp(call.startedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
                ),
                if (call.duration != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DurationUtils.formatShort(call.duration!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            if (onCallBack != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  call.type == CallType.video
                      ? Icons.videocam_outlined
                      : Icons.call_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                onPressed: onCallBack,
                tooltip: 'Call back',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final type = call.type.label;
    if (call.isMissed) return 'Missed';
    if (call.isRejected) return 'Declined';
    return '$type · ${call.direction.label}';
  }

  IconData get _directionIcon {
    if (call.isMissed) return Icons.call_missed;
    if (call.isIncoming) return Icons.call_received;
    return Icons.call_made;
  }

  Color get _statusColor {
    if (call.isMissed) return AppColors.missedCall;
    if (call.isIncoming) return AppColors.incomingCall;
    return AppColors.outgoingCall;
  }
}

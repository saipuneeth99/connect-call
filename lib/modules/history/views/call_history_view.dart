import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/call_tile.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../controllers/call_history_controller.dart';

class CallHistoryView extends GetView<CallHistoryController> {
  const CallHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm,
              ),
              child: Text(
                'Calls',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Obx(() => Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: !controller.showMissedOnly.value,
                        onTap: () => controller.setFilter(false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterChip(
                        label: 'Missed',
                        isSelected: controller.showMissedOnly.value,
                        onTap: () => controller.setFilter(true),
                      ),
                    ],
                  )),
            ),

            // Call list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const LoadingView();
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return ErrorView(
                    message: controller.errorMessage.value,
                    onRetry: controller.loadHistory,
                  );
                }

                if (controller.displayedCalls.isEmpty) {
                  return EmptyView(
                    icon: controller.showMissedOnly.value
                        ? Icons.call_missed
                        : Icons.call_outlined,
                    title: controller.showMissedOnly.value
                        ? 'No missed calls'
                        : 'No recent calls',
                    description: controller.showMissedOnly.value
                        ? 'You haven\'t missed any calls'
                        : 'Your call history will appear here',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadHistory,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: controller.displayedCalls.length,
                    itemBuilder: (context, index) {
                      final call = controller.displayedCalls[index];
                      return CallTile(
                        call: call,
                        onTap: () => Get.toNamed(
                          AppRoutes.callDetail,
                          arguments: call,
                        ),
                        onCallBack: () => Get.toNamed(
                          call.type == CallType.video
                              ? AppRoutes.videoCall
                              : AppRoutes.audioCall,
                          arguments: {
                            'receiverId': call.otherParticipant.id,
                            'callType': call.type,
                            'user': AppUser(
                              id: call.otherParticipant.id,
                              name: call.otherParticipant.name,
                              avatarUrl: call.otherParticipant.avatarUrl,
                              email: '',
                              isOnline: true,
                            ),
                          },
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerTheme.color ?? Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_tile.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../controllers/home_controller.dart';
import '../controllers/main_navigation_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const LoadingView();
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return ErrorView(
              message: controller.errorMessage.value,
              onRetry: controller.loadData,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadData,
            child: ListView(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppDateUtils.formatGreeting(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                                  controller.currentUser.value.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Obx(() => AppAvatar(
                            name: controller.currentUser.value.name,
                            imageUrl: controller.currentUser.value.avatarUrl,
                            size: AvatarSize.large,
                            showOnlineStatus: true,
                            isOnline: true,
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Search Bar (Opens Contacts)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: GestureDetector(
                    onTap: () {
                      if (Get.isRegistered<MainNavigationController>()) {
                        Get.find<MainNavigationController>().changePage(1);
                      } else {
                        Get.toNamed(AppRoutes.contacts);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Search contacts to call...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Favorites with interactive Quick Call sheet
                Obx(() {
                  if (controller.favorites.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No contacts yet',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Search registered email to connect privately',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                              ),
                              onPressed: () {
                                if (Get.isRegistered<
                                    MainNavigationController>()) {
                                  Get.find<MainNavigationController>()
                                      .changePage(1);
                                } else {
                                  Get.toNamed(AppRoutes.contacts);
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: Text(
                          'Favorites',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 106,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          itemCount: controller.favorites.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final user = controller.favorites[index];
                            return SizedBox(
                              width: 68,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _showQuickCallSheet(context, user),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppAvatar(
                                      name: user.name,
                                      imageUrl: user.avatarUrl,
                                      size: AvatarSize.large,
                                      showOnlineStatus: true,
                                      isOnline: user.isOnline,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      user.name.split(' ').first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: AppSpacing.xxxl),

                // Recent calls
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Calls',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (Get.isRegistered<MainNavigationController>()) {
                            Get.find<MainNavigationController>().changePage(2);
                          }
                        },
                        child: const Text('Show all'),
                      ),
                    ],
                  ),
                ),

                Obx(() {
                  if (controller.recentCalls.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: EmptyView(
                        icon: Icons.call_outlined,
                        title: 'No recent calls',
                        description: 'Your call history will appear here',
                      ),
                    );
                  }

                  return Column(
                    children: controller.recentCalls.map((call) {
                      return CallTile(
                        call: call,
                        onTap: () => Get.toNamed(
                          AppRoutes.callDetail,
                          arguments: call,
                        ),
                        onCallBack: () => _startDirectCall(
                          call.otherParticipant.id,
                          call.type,
                          AppUser(
                            id: call.otherParticipant.id,
                            name: call.otherParticipant.name,
                            avatarUrl: call.otherParticipant.avatarUrl,
                            email: '',
                            isOnline: true,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showQuickCallSheet(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Contact Avatar
              AppAvatar(
                name: user.name,
                imageUrl: user.avatarUrl,
                size: AvatarSize.extraLarge,
                showOnlineStatus: true,
                isOnline: user.isOnline,
              ),
              const SizedBox(height: AppSpacing.md),

              // Contact Name & Status
              Text(
                user.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.isOnline ? 'Active now' : user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: user.isOnline
                      ? const Color(0xFF10B981)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Call Options
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call_rounded, color: Colors.white),
                      label: const Text(
                        'Audio Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        _startDirectCall(user.id, CallType.audio, user);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                      label: const Text(
                        'Video Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        _startDirectCall(user.id, CallType.video, user);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.contactDetail, arguments: user);
                },
                child: const Text('View Full Contact Details'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startDirectCall(String userId, CallType type, [AppUser? user]) {
    Get.toNamed(
      type == CallType.video ? AppRoutes.videoCall : AppRoutes.audioCall,
      arguments: {
        'receiverId': userId,
        'callType': type,
        'user': user,
      },
    );
  }
}

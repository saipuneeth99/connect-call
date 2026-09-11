import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_tile.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../controllers/home_controller.dart';

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

                // Search
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.contacts),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Search people...',
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

                // Favorites
                Obx(() {
                  if (controller.favorites.isEmpty) {
                    return const SizedBox.shrink();
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
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          itemCount: controller.favorites.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.lg),
                          itemBuilder: (context, index) {
                            final user = controller.favorites[index];
                            return GestureDetector(
                              onTap: () => Get.toNamed(
                                AppRoutes.contacts,
                                arguments: {'userId': user.id},
                              ),
                              child: Column(
                                children: [
                                  AppAvatar(
                                    name: user.name,
                                    imageUrl: user.avatarUrl,
                                    size: AvatarSize.large,
                                    showOnlineStatus: true,
                                    isOnline: user.isOnline,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    user.name.split(' ').first,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                        onPressed: () {},
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
}

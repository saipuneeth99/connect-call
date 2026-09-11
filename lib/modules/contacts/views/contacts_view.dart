import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../data/models/app_user.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/loading_view.dart';
import '../../../widgets/user_tile.dart';
import '../controllers/contacts_controller.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchController = TextEditingController();

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
                'Contacts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            controller.onSearchChanged('');
                          },
                        )
                      : const SizedBox.shrink()),
                ),
              ),
            ),

            // User list
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const LoadingView();
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return ErrorView(
                    message: controller.errorMessage.value,
                    onRetry: controller.loadUsers,
                  );
                }

                if (controller.filteredUsers.isEmpty) {
                  return EmptyView(
                    icon: controller.searchQuery.value.isNotEmpty
                        ? Icons.search_off
                        : Icons.people_outline,
                    title: controller.searchQuery.value.isNotEmpty
                        ? 'No people found'
                        : 'No contacts yet',
                    description: controller.searchQuery.value.isNotEmpty
                        ? 'Try a different search term'
                        : 'Your contacts will appear here',
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadUsers,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: controller.filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = controller.filteredUsers[index];
                      return UserTile(
                        user: user,
                        onTap: () => Get.toNamed(
                          AppRoutes.contactDetail,
                          arguments: user,
                        ),
                        onAudioCall: () => _startCall(user, CallType.audio),
                        onVideoCall: () => _startCall(user, CallType.video),
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

  void _startCall(AppUser user, CallType type) {
    Get.toNamed(
      type == CallType.video ? AppRoutes.videoCall : AppRoutes.audioCall,
      arguments: {
        'receiverId': user.id,
        'callType': type,
        'user': user,
      },
    );
  }
}

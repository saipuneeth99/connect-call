import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/contact_request.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
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
    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contacts',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Private & End-to-End Secure',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                    final pendingCount = controller.incomingRequests.length;
                    if (pendingCount > 0) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mark_email_unread_rounded,
                              size: 16,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pendingCount new request${pendingCount > 1 ? 's' : ''}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: TextField(
                controller: searchController,
                onChanged: controller.onSearchChanged,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Search by registered email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Obx(() {
                    if (controller.isSearching.value) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (controller.searchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          controller.onSearchChanged('');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
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

                // If user entered search query, show Search Results View
                if (controller.searchQuery.value.trim().isNotEmpty) {
                  return _buildSearchResultsView(context);
                }

                // Default Contacts & Pending Requests View
                return _buildDefaultContactsView(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// View when searching for an email
  Widget _buildSearchResultsView(BuildContext context) {
    if (controller.isSearching.value) {
      return const Center(child: LoadingView());
    }

    if (controller.searchResults.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          children: [
            EmptyView(
              icon: Icons.person_search_rounded,
              title: 'No registered user found',
              description:
                  'No account found for "${controller.searchQuery.value.trim()}".\nPlease verify the registered email address.',
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final result = controller.searchResults[index];
        return _buildSearchResultTile(context, result);
      },
    );
  }

  Widget _buildSearchResultTile(BuildContext context, UserSearchResult result) {
    final theme = Theme.of(context);
    final user = result.user;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildRelationshipAction(context, result),
        ],
      ),
    );
  }

  Widget _buildRelationshipAction(
      BuildContext context, UserSearchResult result) {
    final theme = Theme.of(context);

    switch (result.relationship) {
      case UserRelationship.self:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'You',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case UserRelationship.connected:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _startCall(result.user, CallType.audio),
              icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981)),
              tooltip: 'Audio call',
            ),
            IconButton(
              onPressed: () => _startCall(result.user, CallType.video),
              icon: const Icon(Icons.videocam_rounded, color: Color(0xFF3B82F6)),
              tooltip: 'Video call',
            ),
          ],
        );

      case UserRelationship.requestSent:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Request Sent',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (result.requestId != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Cancel Request',
                onPressed: () => controller.cancelSentRequest(
                  result.requestId!,
                  result.user.id,
                ),
              ),
          ],
        );

      case UserRelationship.requestReceived:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                final req = controller.incomingRequests.firstWhereOrNull(
                  (r) => r.senderId == result.user.id || r.id == result.requestId,
                );
                if (req != null) {
                  controller.acceptContactRequest(req);
                } else if (result.requestId != null) {
                  controller.acceptContactRequest(
                    ContactRequest(
                      id: result.requestId!,
                      senderId: result.user.id,
                      receiverId: '',
                      status: ContactRequestStatus.pending,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      sender: result.user,
                    ),
                  );
                }
              },
              child: const Text('Accept'),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                if (result.requestId != null) {
                  controller.declineContactRequest(result.requestId!);
                }
              },
              child: const Text('Decline'),
            ),
          ],
        );

      case UserRelationship.none:
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () => controller.sendContactRequest(result.user),
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add'),
        );
    }
  }

  /// Default view showing Pending Requests + My Contacts
  Widget _buildDefaultContactsView(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: controller.loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Section: Incoming Contact Requests
          if (controller.incomingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Incoming Requests (${controller.incomingRequests.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ...controller.incomingRequests.map((request) {
              final sender = request.sender ??
                  AppUser(
                    id: request.senderId,
                    name: 'User (${request.senderId.substring(0, 5)})',
                    email: '',
                    isOnline: false,
                  );
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: sender.name,
                      imageUrl: sender.avatarUrl,
                      size: AvatarSize.medium,
                      showOnlineStatus: true,
                      isOnline: sender.isOnline,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (sender.email.isNotEmpty)
                            Text(
                              sender.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => controller.acceptContactRequest(request),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Decline',
                          onPressed: () =>
                              controller.declineContactRequest(request.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: AppSpacing.xl, indent: AppSpacing.xl, endIndent: AppSpacing.xl),
          ],

          // Section: Sent Requests (Outgoing)
          if (controller.sentRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Text(
                'Sent Requests (${controller.sentRequests.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            ...controller.sentRequests.map((request) {
              final receiver = request.receiver ??
                  AppUser(
                    id: request.receiverId,
                    name: 'Pending User',
                    email: '',
                    isOnline: false,
                  );
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      name: receiver.name,
                      imageUrl: receiver.avatarUrl,
                      size: AvatarSize.small,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiver.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (receiver.email.isNotEmpty)
                            Text(
                              receiver.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => controller.cancelSentRequest(
                        request.id,
                        request.receiverId,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: AppSpacing.xl, indent: AppSpacing.xl, endIndent: AppSpacing.xl),
          ],

          // Section: My Contacts Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xs,
            ),
            child: Text(
              'My Contacts (${controller.contacts.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Section: Contacts List or Empty State
          if (controller.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxxl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 38,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No contacts yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your contact list is private & secure.\nSearch above by a person\'s registered email to send an invite.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ...controller.contacts.map((user) {
              return UserTile(
                user: user,
                onTap: () => Get.toNamed(
                  AppRoutes.contactDetail,
                  arguments: user,
                ),
                onAudioCall: () => _startCall(user, CallType.audio),
                onVideoCall: () => _startCall(user, CallType.video),
              );
            }),
        ],
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

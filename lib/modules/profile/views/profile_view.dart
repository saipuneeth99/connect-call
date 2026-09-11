import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/app_avatar.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl,
              ),
              child: Text(
                'Profile',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Profile card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Obx(() => Column(
                    children: [
                      GestureDetector(
                        onTap: () => controller.showPhotoOptionsSheet(context),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AppAvatar(
                              name: controller.user.value.name,
                              imageUrl: controller.user.value.avatarUrl,
                              size: AvatarSize.extraLarge,
                              showOnlineStatus: true,
                              isOnline: true,
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (controller.isUploadingAvatar.value)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        controller.user.value.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        controller.user.value.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  )),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Account section
            _SectionTitle(title: 'Account', theme: theme),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => Get.toNamed(AppRoutes.editProfile),
            ),
            _SettingsTile(
              icon: Icons.photo_camera_outlined,
              title: 'Change Profile Picture',
              onTap: () => controller.showPhotoOptionsSheet(context),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Preferences
            _SectionTitle(title: 'Preferences', theme: theme),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'System',
              onTap: () => _showThemeDialog(context),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.xxl),

            // About
            _SectionTitle(title: 'About', theme: theme),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'About ConnectCall',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  final authController = Get.find<AuthController>();
                  authController.logout();
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          SimpleDialogOption(
            child: const Text('System'),
            onPressed: () {
              Get.changeThemeMode(ThemeMode.system);
              Get.back();
            },
          ),
          SimpleDialogOption(
            child: const Text('Light'),
            onPressed: () {
              Get.changeThemeMode(ThemeMode.light);
              Get.back();
            },
          ),
          SimpleDialogOption(
            child: const Text('Dark'),
            onPressed: () {
              Get.changeThemeMode(ThemeMode.dark);
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}

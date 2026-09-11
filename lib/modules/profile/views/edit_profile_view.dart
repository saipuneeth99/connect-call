import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final controller = Get.find<ProfileController>();
  late final TextEditingController nameController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: controller.user.value.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Obx(() => Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            controller.showPhotoOptionsSheet(context),
                        child: Stack(
                          children: [
                            AppAvatar(
                              name: controller.user.value.name,
                              imageUrl: controller.user.value.avatarUrl,
                              size: AvatarSize.extraLarge,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                  )),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => controller.showPhotoOptionsSheet(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Change Photo'),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppTextField(
                controller: nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline,
                validator: Validators.validateName,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Obx(() => AppButton(
                    label: 'Save Changes',
                    isLoading: controller.isLoading.value,
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        await controller.updateName(nameController.text.trim());
                        Get.back();
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

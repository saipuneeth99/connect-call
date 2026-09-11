import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController =
        TextEditingController(text: controller.user.value.name);
    final formKey = GlobalKey<FormState>();

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
              Obx(() => AppAvatar(
                    name: controller.user.value.name,
                    imageUrl: controller.user.value.avatarUrl,
                    size: AvatarSize.extraLarge,
                  )),
              TextButton.icon(
                onPressed: () {},
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
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        controller.updateName(nameController.text.trim());
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

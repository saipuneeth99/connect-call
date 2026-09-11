import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_action_button.dart';
import '../controllers/call_controller.dart';

class OutgoingCallView extends GetView<CallController> {
  const OutgoingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    // Start the call when this view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && controller.callStatus.value == CallStatus.idle) {
        controller.startOutgoingCall(
          receiverId: args['receiverId'] as String,
          type: args['callType'] as CallType,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Status
            Obx(() => Text(
                  controller.callStatus.value.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                )),

            const SizedBox(height: AppSpacing.xxxl),

            // Avatar
            Obx(() => AppAvatar(
                  name: controller.remoteUser.value?.name,
                  imageUrl: controller.remoteUser.value?.avatarUrl,
                  size: AvatarSize.call,
                  backgroundColor: AppColors.callSurface,
                )),

            const SizedBox(height: AppSpacing.xxl),

            // Name
            Obx(() => Text(
                  controller.remoteUser.value?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                )),

            const SizedBox(height: AppSpacing.sm),

            // Call type
            Obx(() => Text(
                  controller.callType.value.label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                )),

            const Spacer(flex: 3),

            // Cancel button
            CallActionButton(
              icon: Icons.call_end,
              label: 'Cancel',
              isDestructive: true,
              size: 72,
              onPressed: controller.endCall,
            ),

            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }
}

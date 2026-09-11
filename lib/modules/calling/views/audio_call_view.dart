import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_action_button.dart';
import '../controllers/call_controller.dart';

class AudioCallView extends GetView<CallController> {
  const AudioCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Status
            Obx(() => Text(
                  controller.callStatus.value == CallStatus.connected
                      ? 'Connected'
                      : controller.callStatus.value.label,
                  style: TextStyle(
                    color: controller.callStatus.value == CallStatus.connected
                        ? AppColors.online
                        : Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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

            const SizedBox(height: AppSpacing.md),

            // Duration
            Obx(() => Text(
                  controller.callDuration.value,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                )),

            const Spacer(flex: 3),

            // Controls
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.huge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Obx(() => CallActionButton(
                        icon: controller.isMuted.value
                            ? Icons.mic_off
                            : Icons.mic,
                        label: 'Mute',
                        isActive: controller.isMuted.value,
                        onPressed: controller.toggleMute,
                      )),
                  Obx(() => CallActionButton(
                        icon: controller.isSpeakerOn.value
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label: 'Speaker',
                        isActive: controller.isSpeakerOn.value,
                        onPressed: controller.toggleSpeaker,
                      )),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // End call
            CallActionButton(
              icon: Icons.call_end,
              label: 'End',
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

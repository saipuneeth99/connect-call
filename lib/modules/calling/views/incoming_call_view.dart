import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_ripple_animation.dart';
import '../controllers/call_controller.dart';

class IncomingCallView extends GetView<CallController> {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Top Category Pill
            Obx(() {
              final isVideo = controller.callType.value == CallType.video;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo
                          ? Icons.videocam_rounded
                          : Icons.phone_in_talk_rounded,
                      color: const Color(0xFF38BDF8),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'Incoming video call' : 'Incoming voice call',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Spacer(flex: 1),

            // Pulsing Center Avatar
            Center(
              child: CallRippleAnimation(
                color: const Color(0xFF10B981),
                minRadius: 75,
                maxRadius: 165,
                ripplesCount: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Obx(() => AppAvatar(
                        name: controller.remoteUser.value?.name,
                        imageUrl: controller.remoteUser.value?.avatarUrl,
                        size: AvatarSize.call,
                        backgroundColor: const Color(0xFF1E293B),
                      )),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Caller Name
            Obx(() => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text(
                    controller.remoteUser.value?.name ?? 'Incoming Call',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                )),

            const SizedBox(height: 6),

            // Subtitle
            Obx(() {
              final user = controller.remoteUser.value;
              return Text(
                user != null && user.email.isNotEmpty
                    ? user.email
                    : 'ConnectCall Secure Line',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              );
            }),

            const Spacer(flex: 3),

            // Android-Style Dual Action Buttons (Decline & Answer)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: AppSpacing.xxl,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          controller.rejectCall();
                        },
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48)
                                    .withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Decline',
                        style: TextStyle(
                          color: Color(0xFFFDA4AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Answer Button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          controller.acceptCall();
                        },
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.5),
                                blurRadius: 22,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Obx(() => Icon(
                                controller.callType.value == CallType.video
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: Colors.white,
                                size: 34,
                              )),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Answer',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

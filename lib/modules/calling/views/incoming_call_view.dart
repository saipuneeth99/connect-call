import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF080C15),
      body: Stack(
        children: [
          // Ambient breathing background lights
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Incoming Call Badge
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.callType.value == CallType.video
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,
                            color: const Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.callType.value == CallType.video
                                ? 'Incoming Video Call'
                                : 'Incoming Audio Call',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    )),

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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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

                const SizedBox(height: AppSpacing.xxxl),

                // Name
                Obx(() => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      child: Text(
                        controller.remoteUser.value?.name ?? 'Incoming Call',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    )),

                const SizedBox(height: AppSpacing.sm),

                Obx(() {
                  final user = controller.remoteUser.value;
                  return Text(
                    user != null && user.email.isNotEmpty
                        ? user.email
                        : 'Connect Call HD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }),

                const Spacer(flex: 3),

                // Glassmorphic Accept / Decline Actions Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.xxl,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline Button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE11D48)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: const Color(0xFFE11D48),
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: controller.rejectCall,
                                customBorder: const CircleBorder(),
                                splashColor: Colors.white38,
                                child: const SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Decline',
                            style: TextStyle(
                              color: Color(0xFFFDA4AF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Accept Button
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Material(
                              color: const Color(0xFF10B981),
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: controller.acceptCall,
                                customBorder: const CircleBorder(),
                                splashColor: Colors.white38,
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(
                                    controller.callType.value == CallType.video
                                        ? Icons.videocam_rounded
                                        : Icons.call_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accept',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 13,
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/app_avatar.dart';
import '../controllers/call_controller.dart';

class IncomingCallView extends GetView<CallController> {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Label
            Obx(() => Text(
                  controller.callType.value == CallType.video
                      ? 'Incoming Video Call'
                      : 'Incoming Audio Call',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                )),

            const SizedBox(height: AppSpacing.xxxl),

            // Avatar with pulse animation
            _PulsingAvatar(controller: controller),

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

            Obx(() {
              final user = controller.remoteUser.value;
              if (user != null && user.isOnline) {
                return const Text(
                  'Online',
                  style: TextStyle(color: AppColors.online, fontSize: 14),
                );
              }
              return const SizedBox.shrink();
            }),

            const Spacer(flex: 3),

            // Accept/Decline buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.massive),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      GestureDetector(
                        onTap: controller.rejectCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.callReject,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: controller.acceptCall,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.callAccept,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.callType.value == CallType.video
                                ? Icons.videocam
                                : Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  final CallController controller;

  const _PulsingAvatar({required this.controller});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Obx(() => AppAvatar(
                name: widget.controller.remoteUser.value?.name,
                imageUrl: widget.controller.remoteUser.value?.avatarUrl,
                size: AvatarSize.call,
                backgroundColor: AppColors.callSurface,
              )),
        );
      },
    );
  }
}

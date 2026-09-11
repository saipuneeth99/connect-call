import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../data/services/calling_service.dart';
import '../../../data/services/livekit_calling_service.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_ripple_animation.dart';
import '../controllers/call_controller.dart';

class VideoCallView extends GetView<CallController> {
  const VideoCallView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initiate outgoing call on screen open if arguments provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        final receiverId = args['receiverId'] as String?;
        final type = (args['callType'] as CallType?) ?? CallType.video;
        final user = args['user'] as AppUser?;
        if (receiverId != null && receiverId.isNotEmpty) {
          controller.startOutgoingCall(
            receiverId: receiverId,
            type: type,
            fallbackUser: user,
          );
        }
      }
    });

    final screenSize = MediaQuery.of(context).size;
    final callingService =
        Get.isRegistered<CallingService>() ? Get.find<CallingService>() : null;
    final liveKit =
        callingService is LiveKitCallingService ? callingService : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            controller.endCall();
          }
        },
        child: Stack(
          children: [
            // Background Video Stream (Remote when connected, or local preview during ringing)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF0F172A),
              child: liveKit != null
                  ? ValueListenableBuilder<VideoTrack?>(
                      valueListenable: liveKit.remoteVideoTrackNotifier,
                      builder: (context, remoteTrack, _) {
                        if (remoteTrack != null) {
                          return VideoTrackRenderer(
                            remoteTrack,
                            fit: VideoViewFit.cover,
                          );
                        }
                        return ValueListenableBuilder<LocalVideoTrack?>(
                          valueListenable: liveKit.localVideoTrackNotifier,
                          builder: (context, localTrack, _) {
                            return Obx(() {
                              final status = controller.callStatus.value;
                              final isRinging = status == CallStatus.calling ||
                                  status == CallStatus.ringing;

                              if (isRinging &&
                                  localTrack != null &&
                                  controller.isCameraOn.value) {
                                return Stack(
                                  children: [
                                    VideoTrackRenderer(
                                      localTrack,
                                      fit: VideoViewFit.cover,
                                      mirrorMode: VideoViewMirrorMode.mirror,
                                    ),
                                    Container(
                                      color: Colors.black.withValues(alpha: 0.35),
                                    ),
                                    _buildRingingOverlay(controller),
                                  ],
                                );
                              }
                              return _buildRemotePlaceholder(controller);
                            });
                          },
                        );
                      },
                    )
                  : _buildRemotePlaceholder(controller),
            ),

            // Tap detector overlay covering full screen to toggle controls
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.toggleControlsVisibility,
              ),
            ),

            // Top Floating Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Obx(() => IgnorePointer(
                    ignoring: !controller.showControls.value,
                    child: AnimatedOpacity(
                      opacity: controller.showControls.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          MediaQuery.of(context).padding.top + AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            // End / Minimize Call button
                            IconButton(
                              onPressed: controller.endCall,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),

                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.remoteUser.value?.name ?? 'Video Call',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: controller.callStatus.value ==
                                                CallStatus.connected
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      controller.callStatus.value ==
                                              CallStatus.connected
                                          ? controller.callDuration.value
                                          : controller.callStatus.value.label,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Flip Camera Button
                          IconButton(
                            onPressed: controller.switchCamera,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))),
            ),

            // Local PiP Preview (Floating Camera View in Top Right)
            if (liveKit != null)
              ValueListenableBuilder<VideoTrack?>(
                valueListenable: liveKit.remoteVideoTrackNotifier,
                builder: (context, remoteTrack, _) {
                  return ValueListenableBuilder<LocalVideoTrack?>(
                    valueListenable: liveKit.localVideoTrackNotifier,
                    builder: (context, localTrack, _) {
                      return Obx(() {
                        final status = controller.callStatus.value;
                        final isRinging = status == CallStatus.calling ||
                            status == CallStatus.ringing;

                        // Only show PiP if remote track is visible, or if connected, and camera is on
                        final showPiP = (remoteTrack != null || !isRinging) &&
                            controller.isCameraOn.value &&
                            localTrack != null;

                        if (!showPiP) return const SizedBox.shrink();

                        return Positioned(
                          top: MediaQuery.of(context).padding.top + 70,
                          right: AppSpacing.lg,
                          child: AnimatedOpacity(
                            opacity: controller.isCameraOn.value ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: screenSize.width * 0.32,
                              height: screenSize.width * 0.46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: VideoTrackRenderer(
                                  localTrack,
                                  fit: VideoViewFit.cover,
                                  mirrorMode: VideoViewMirrorMode.mirror,
                                ),
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  );
                },
              ),

            // Glassmorphic Floating Bottom Dock Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Obx(() => IgnorePointer(
                    ignoring: !controller.showControls.value,
                    child: AnimatedOpacity(
                      opacity: controller.showControls.value ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xl,
                        AppSpacing.md,
                        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm + 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Mute
                                Obx(() => _ControlDockButton(
                                      icon: controller.isMuted.value
                                          ? Icons.mic_off_rounded
                                          : Icons.mic_rounded,
                                      isActive: controller.isMuted.value,
                                      activeColor: const Color(0xFFF43F5E),
                                      onPressed: controller.toggleMute,
                                    )),

                                // Video on/off
                                Obx(() => _ControlDockButton(
                                      icon: controller.isCameraOn.value
                                          ? Icons.videocam_rounded
                                          : Icons.videocam_off_rounded,
                                      isActive: !controller.isCameraOn.value,
                                      activeColor: const Color(0xFFF43F5E),
                                      onPressed: controller.toggleCamera,
                                    )),

                                // Speakerphone Toggle
                                Obx(() => _ControlDockButton(
                                      icon: controller.isSpeakerOn.value
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_down_rounded,
                                      isActive: controller.isSpeakerOn.value,
                                      activeColor: const Color(0xFF38BDF8),
                                      onPressed: controller.toggleSpeaker,
                                    )),

                                // Switch Camera
                                _ControlDockButton(
                                  icon: Icons.cameraswitch_rounded,
                                  onPressed: controller.switchCamera,
                                ),

                                // End Call Button
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE11D48)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: const Color(0xFFE11D48),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      onTap: controller.endCall,
                                      customBorder: const CircleBorder(),
                                      child: const SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: Icon(
                                          Icons.call_end_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingingOverlay(CallController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CallRippleAnimation(
            color: const Color(0xFF38BDF8),
            minRadius: 55,
            maxRadius: 120,
            ripplesCount: 3,
            child: AppAvatar(
              name: controller.remoteUser.value?.name,
              imageUrl: controller.remoteUser.value?.avatarUrl,
              size: AvatarSize.large,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            controller.remoteUser.value?.name ?? 'Contact',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  controller.callStatus.value == CallStatus.calling
                      ? 'Calling...'
                      : 'Ringing...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemotePlaceholder(CallController controller) {
    return Obx(() {
      final user = controller.remoteUser.value;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              name: user?.name,
              imageUrl: user?.avatarUrl,
              size: AvatarSize.extraLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              user?.name ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.callStatus.value == CallStatus.connected
                  ? 'Video connecting...'
                  : controller.callStatus.value.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ControlDockButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _ControlDockButton({
    required this.icon,
    this.isActive = false,
    this.activeColor = const Color(0xFF38BDF8),
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? activeColor.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? activeColor : Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

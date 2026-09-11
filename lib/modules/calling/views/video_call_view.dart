import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/call_status.dart';
import '../../../data/services/calling_service.dart';
import '../../../data/services/livekit_calling_service.dart';
import '../../../widgets/call_action_button.dart';
import '../controllers/call_controller.dart';

class VideoCallView extends GetView<CallController> {
  const VideoCallView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final callingService =
        Get.isRegistered<CallingService>() ? Get.find<CallingService>() : null;
    final liveKit =
        callingService is LiveKitCallingService ? callingService : null;

    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: GestureDetector(
        onTap: controller.toggleControlsVisibility,
        child: Stack(
          children: [
            // Remote video (full screen)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.callBackground,
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
                        return _buildRemotePlaceholder(controller);
                      },
                    )
                  : _buildRemotePlaceholder(controller),
            ),

            // Local camera preview
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              right: AppSpacing.lg,
              child: Obx(() => AnimatedOpacity(
                    opacity: controller.isCameraOn.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: screenSize.width * 0.28,
                      height: screenSize.width * 0.38,
                      decoration: BoxDecoration(
                        color: AppColors.callSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: liveKit != null
                            ? ValueListenableBuilder<LocalVideoTrack?>(
                                valueListenable:
                                    liveKit.localVideoTrackNotifier,
                                builder: (context, localTrack, _) {
                                  if (localTrack != null &&
                                      controller.isCameraOn.value) {
                                    return VideoTrackRenderer(
                                      localTrack,
                                      fit: VideoViewFit.cover,
                                      mirrorMode: VideoViewMirrorMode.mirror,
                                    );
                                  }
                                  return _buildLocalPlaceholder();
                                },
                              )
                            : _buildLocalPlaceholder(),
                      ),
                    ),
                  )),
            ),

            // Top info bar
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              left: AppSpacing.lg,
              child: Obx(() => AnimatedOpacity(
                    opacity: controller.showControls.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.remoteUser.value?.name ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (controller.callStatus.value ==
                                CallStatus.connected)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.online,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              controller.callStatus.value ==
                                      CallStatus.connected
                                  ? controller.callDuration.value
                                  : controller.callStatus.value.label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Obx(() => AnimatedOpacity(
                    opacity: controller.showControls.value ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        MediaQuery.of(context).padding.bottom +
                            AppSpacing.xxxl,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
                                icon: controller.isCameraOn.value
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                label: 'Camera',
                                isActive: !controller.isCameraOn.value,
                                onPressed: controller.toggleCamera,
                              )),
                          CallActionButton(
                            icon: Icons.cameraswitch,
                            label: 'Flip',
                            onPressed: controller.switchCamera,
                          ),
                          CallActionButton(
                            icon: Icons.call_end,
                            label: 'End',
                            isDestructive: true,
                            onPressed: controller.endCall,
                          ),
                        ],
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemotePlaceholder(CallController controller) {
    return Obx(() {
      if (controller.callStatus.value == CallStatus.connected) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Connecting video stream...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Text(
          controller.callStatus.value.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      );
    });
  }

  Widget _buildLocalPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 32,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'You',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

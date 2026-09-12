import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/call_status.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/call_ripple_animation.dart';
import '../controllers/call_controller.dart';

class AudioCallView extends GetView<CallController> {
  const AudioCallView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initiate call on screen open if arguments provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null) {
        final receiverId = args['receiverId'] as String?;
        final type = (args['callType'] as CallType?) ?? CallType.audio;
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Top Status & Security Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70, size: 30),
                    tooltip: 'Minimize',
                    onPressed: () => Get.back(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 13, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // balance back button
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Contact Avatar with Pulsing Halo
            Obx(() {
              final isConnected =
                  controller.callStatus.value == CallStatus.connected;
              final haloColor = isConnected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF38BDF8);

              return CallRippleAnimation(
                color: haloColor,
                minRadius: 70,
                maxRadius: 150,
                ripplesCount: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: haloColor.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    name: controller.remoteUser.value?.name,
                    imageUrl: controller.remoteUser.value?.avatarUrl,
                    size: AvatarSize.call,
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Contact Name
            Obx(() => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text(
                    controller.remoteUser.value?.name ?? 'Connecting...',
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

            const SizedBox(height: 6),

            // Call Status / Duration / Audio Route Subtitle
            Obx(() {
              final status = controller.callStatus.value;
              final isConnected = status == CallStatus.connected;
              final isRinging = status == CallStatus.ringing;
              final isCalling = status == CallStatus.calling;

              String labelText = status.label;
              Color labelColor = Colors.white70;

              if (isConnected) {
                labelText = controller.callDuration.value;
                labelColor = const Color(0xFF34D399);
              } else if (isRinging) {
                labelText = 'Ringing...';
                labelColor = const Color(0xFF93C5FD);
              } else if (isCalling) {
                labelText = 'Calling...';
                labelColor = const Color(0xFF93C5FD);
              } else if (status.isTerminal) {
                labelText = 'Call Ended';
                labelColor = const Color(0xFFFDA4AF);
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isConnected) ...[
                    Icon(
                      controller.isSpeakerOn.value
                          ? Icons.volume_up_rounded
                          : Icons.phone_in_talk_rounded,
                      size: 15,
                      color: labelColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labelText,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFeatures: isConnected
                          ? const [FontFeature.tabularFigures()]
                          : null,
                      letterSpacing: isConnected ? 1.0 : 0.2,
                    ),
                  ),
                ],
              );
            }),

            // Optional Error Banner
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(
                      color: Color(0xFFFDA4AF),
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const Spacer(flex: 2),

            // Android-Style In-Call Control Grid (2 Rows x 3 Columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                children: [
                  // Row 1: Mute | Keypad | Speaker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Obx(() => _AndroidDialerButton(
                            icon: controller.isMuted.value
                                ? Icons.mic_off_rounded
                                : Icons.mic_rounded,
                            label: controller.isMuted.value ? 'Muted' : 'Mute',
                            isActive: controller.isMuted.value,
                            activeColor: const Color(0xFFEF4444),
                            onTap: controller.toggleMute,
                          )),
                      _AndroidDialerButton(
                        icon: Icons.dialpad_rounded,
                        label: 'Keypad',
                        onTap: () => _showKeypadSheet(context),
                      ),
                      Obx(() => _AndroidDialerButton(
                            icon: controller.isSpeakerOn.value
                                ? Icons.volume_up_rounded
                                : Icons.volume_down_rounded,
                            label: controller.isSpeakerOn.value
                                ? 'Speaker'
                                : 'Earpiece',
                            isActive: controller.isSpeakerOn.value,
                            activeColor: const Color(0xFF38BDF8),
                            onTap: controller.toggleSpeaker,
                          )),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Row 2: Video Call | Hold | Add Call
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AndroidDialerButton(
                        icon: Icons.videocam_rounded,
                        label: 'Video call',
                        activeColor: const Color(0xFFA855F7),
                        onTap: controller.switchToVideoCall,
                      ),
                      _AndroidDialerButton(
                        icon: Icons.pause_rounded,
                        label: 'Hold',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          controller.toggleMute();
                        },
                      ),
                      _AndroidDialerButton(
                        icon: Icons.person_add_rounded,
                        label: 'Add call',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Get.toNamed(AppRoutes.contacts);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Bottom Centered Large Red End Call Button (Android Style)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    controller.endCall();
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeypadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF131926).withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Dialed Digits Display
                  Obx(() => Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          controller.dialedDigits.value.isEmpty
                              ? 'Dial digits'
                              : controller.dialedDigits.value,
                          style: TextStyle(
                            color: controller.dialedDigits.value.isEmpty
                                ? Colors.white30
                                : Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4.0,
                          ),
                        ),
                      )),

                  const SizedBox(height: AppSpacing.lg),

                  _buildKeypadRow(['1', '2', '3'], ['', 'ABC', 'DEF']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['*', '0', '#'], ['', '+', '']),

                  const SizedBox(height: AppSpacing.lg),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Hide Keypad',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(List<String> digits, List<String> letters) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(digits.length, (i) {
        final d = digits[i];
        final l = letters[i];
        return Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              controller.dialDigit(d);
            },
            child: SizedBox(
              width: 68,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    d,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (l.isNotEmpty)
                    Text(
                      l,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AndroidDialerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _AndroidDialerButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = const Color(0xFF38BDF8),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? activeColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

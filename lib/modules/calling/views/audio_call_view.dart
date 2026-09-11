import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
      backgroundColor: const Color(0xFF080C15),
      body: Stack(
        children: [
          // Ambient breathing background lighting
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Minimize button
                      Material(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Get.back(),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),

                      // Encryption capsule badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF10B981),
                              size: 13,
                            ),
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

                      // HD audio indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'HD',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Center Avatar with Radar Ripple Waves
                Center(
                  child: Obx(() {
                    final isConnected =
                        controller.callStatus.value == CallStatus.connected;
                    final rippleColor = isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFF38BDF8);

                    return CallRippleAnimation(
                      color: rippleColor,
                      minRadius: 75,
                      maxRadius: 165,
                      ripplesCount: 3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isConnected
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF06B6D4)
                                  ]
                                : [
                                    const Color(0xFF38BDF8),
                                    const Color(0xFF818CF8)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rippleColor.withValues(alpha: 0.4),
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
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Contact Name
                Obx(() => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
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

                const SizedBox(height: AppSpacing.sm),

                // Dynamic Status & Duration Pill
                Obx(() {
                  final status = controller.callStatus.value;
                  final isConnected = status == CallStatus.connected;
                  final isRinging = status == CallStatus.ringing;
                  final isCalling = status == CallStatus.calling;
                  final isTerminal = status.isTerminal;

                  Color badgeBg = Colors.white.withValues(alpha: 0.08);
                  Color badgeBorder = Colors.white.withValues(alpha: 0.12);
                  Color dotColor = const Color(0xFF38BDF8);
                  String label = status.label;

                  if (isConnected) {
                    badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
                    badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.4);
                    dotColor = const Color(0xFF10B981);
                    label = controller.callDuration.value;
                  } else if (isRinging) {
                    badgeBg = const Color(0xFF6366F1).withValues(alpha: 0.15);
                    badgeBorder = const Color(0xFF6366F1).withValues(alpha: 0.35);
                    dotColor = const Color(0xFF818CF8);
                    label = 'Ringing...';
                  } else if (isCalling) {
                    badgeBg = const Color(0xFF0284C7).withValues(alpha: 0.15);
                    badgeBorder = const Color(0xFF0284C7).withValues(alpha: 0.35);
                    dotColor = const Color(0xFF38BDF8);
                    label = 'Calling...';
                  } else if (isTerminal) {
                    badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
                    badgeBorder = const Color(0xFFEF4444).withValues(alpha: 0.4);
                    dotColor = const Color(0xFFEF4444);
                    label = status.label;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            boxShadow: [
                              BoxShadow(
                                color: dotColor.withValues(alpha: 0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isConnected
                                ? const Color(0xFF34D399)
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFeatures: isConnected
                                ? const [FontFeature.tabularFigures()]
                                : null,
                            letterSpacing: isConnected ? 1.0 : 0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.xxl),

                // Real-time Soundwave Visualizer (active when connected)
                Obx(() {
                  if (controller.callStatus.value == CallStatus.connected) {
                    return const _AudioWaveBar();
                  }
                  return const SizedBox(height: 28);
                }),

                // Error message if any
                Obx(() {
                  if (controller.errorMessage.value.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
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

                // Glassmorphic Floating Control Dock
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute button
                            Obx(() => _CallIconButton(
                                  icon: controller.isMuted.value
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded,
                                  label: controller.isMuted.value
                                      ? 'Muted'
                                      : 'Mute',
                                  isActive: controller.isMuted.value,
                                  activeColor: const Color(0xFFF43F5E),
                                  onPressed: controller.toggleMute,
                                )),

                            // Keypad button (opens dialpad sheet)
                            _CallIconButton(
                              icon: Icons.dialpad_rounded,
                              label: 'Keypad',
                              onPressed: () => _showKeypadSheet(context),
                            ),

                            // Speaker button
                            Obx(() => _CallIconButton(
                                  icon: controller.isSpeakerOn.value
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_down_rounded,
                                  label: controller.isSpeakerOn.value
                                      ? 'Speaker'
                                      : 'Earpiece',
                                  isActive: controller.isSpeakerOn.value,
                                  activeColor: const Color(0xFF38BDF8),
                                  onPressed: controller.toggleSpeaker,
                                )),

                            // Upgrade to Video
                            _CallIconButton(
                              icon: Icons.videocam_rounded,
                              label: 'Video',
                              activeColor: const Color(0xFFA855F7),
                              onPressed: controller.switchToVideoCall,
                            ),

                            // End / Cancel Call Button
                            _CallEndButton(
                              onPressed: controller.endCall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
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
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Digits display
                  Obx(() => Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          controller.dialedDigits.value.isEmpty
                              ? 'Tap digits to dial'
                              : controller.dialedDigits.value,
                          style: TextStyle(
                            color: controller.dialedDigits.value.isEmpty
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.0,
                          ),
                        ),
                      )),

                  const SizedBox(height: AppSpacing.xl),

                  // Keypad 3x4 grid
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: AppSpacing.md),
                  _buildKeypadRow(['*', '0', '#']),

                  const SizedBox(height: AppSpacing.xl),

                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Hide Keypad',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
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

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        return Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.dialDigit(d);
            },
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                d,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AudioWaveBar extends StatefulWidget {
  const _AudioWaveBar();

  @override
  State<_AudioWaveBar> createState() => _AudioWaveBarState();
}

class _AudioWaveBarState extends State<_AudioWaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _bar(8 + 14 * val),
            _bar(16 + 18 * (1 - val)),
            _bar(10 + 24 * val),
            _bar(24 + 14 * (1 - val)),
            _bar(14 + 20 * val),
            _bar(20 + 16 * (1 - val)),
            _bar(11 + 22 * val),
            _bar(18 + 12 * (1 - val)),
            _bar(9 + 16 * val),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _CallIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _CallIconButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor = const Color(0xFF38BDF8),
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 52,
              height: 52,
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
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CallEndButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CallEndButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: const Color(0xFFE11D48),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              splashColor: Colors.white38,
              child: const SizedBox(
                width: 58,
                height: 58,
                child: Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'End',
          style: TextStyle(
            color: Color(0xFFFDA4AF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

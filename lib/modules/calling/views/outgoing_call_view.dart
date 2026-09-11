import 'package:flutter/material.dart';
import 'audio_call_view.dart';

/// OutgoingCallView delegates directly to the unified AudioCallView,
/// ensuring a smooth, single-screen lifecycle without route churn.
class OutgoingCallView extends StatelessWidget {
  const OutgoingCallView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AudioCallView();
  }
}

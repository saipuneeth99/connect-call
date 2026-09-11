import 'dart:io';

import 'package:flutter/foundation.dart';

class PlatformUtils {
  PlatformUtils._();

  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMobile => isIOS || isAndroid;

  static double get defaultBorderRadius => isIOS ? 12.0 : 8.0;
  static double get cardBorderRadius => isIOS ? 16.0 : 12.0;
  static double get buttonBorderRadius => isIOS ? 14.0 : 12.0;
  static double get inputBorderRadius => isIOS ? 12.0 : 8.0;
  static double get avatarBorderRadius => isIOS ? 24.0 : 20.0;

  static double get horizontalPadding => isIOS ? 20.0 : 16.0;
  static double get verticalSpacing => isIOS ? 24.0 : 20.0;
}

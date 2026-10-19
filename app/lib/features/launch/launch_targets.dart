import 'package:flutter/widgets.dart';

/// Global anchors used by the opening animation so the landing compass can be
/// measured from the real page instead of estimated from padding constants.
class LaunchTargets {
  const LaunchTargets._();

  static final GlobalKey homeCompass = GlobalKey(debugLabel: 'home-compass');
  static final GlobalKey onboardingCompass = GlobalKey(debugLabel: 'onboarding-compass');
}

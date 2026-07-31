import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter/foundation.dart';

class FeatureFlag {
  static const bool isBackgroundSyncEnabled = true;
  static bool get isInAppTorEnabled => CakeTor.instance is! CakeTorDisabled;
  static const int verificationWordsCount = kDebugMode || kProfileMode ? 0 : 2;
  static const bool hasDevOptions =
      bool.fromEnvironment('hasDevOptions', defaultValue: kDebugMode || kProfileMode);
  static const bool hasBitcoinViewOnly = true;
  static const bool customBackgroundEnabled = false;
  static const bool duressPinEnabled = true;
  static const bool isEVMChainSwitcherEnabled = false;
  static const bool isAutomaticNodeSwitchingEnabled = true;
  static const bool hasNewUi = true;
  static const bool hasNewUiExtraPages = true;
}

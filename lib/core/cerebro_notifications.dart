import 'dart:io';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CerebroNotifications {
  CerebroNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      windows: WindowsInitializationSettings(
        appName: 'Mi Bóveda',
        appUserModelId: 'com.miboveda.wallet',
        guid: 'f7a0b1c2-d3e4-4f56-a7b8-9c0d1e2f3a4b',
      ),
    );
    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    try {
      await initialize();
      if (Platform.isAndroid) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      return true;
    } catch (e) {
      printV('CerebroNotifications.requestPermission error: $e');
      return false;
    }
  }

  static Future<void> show(String title, String body) async {
    try {
      await initialize();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'cerebro',
          'Mi Bóveda Cerebro',
          channelDescription: 'Avisos del servicio Mi Bóveda',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.hashCode,
        title,
        body,
        details,
      );
    } catch (e) {
      printV('CerebroNotifications.show error: $e');
    }
  }
}

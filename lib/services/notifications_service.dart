import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

  final androidInit = const AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosInit = const DarwinInitializationSettings();
  final initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

  await _plugin.initialize(initSettings);
  // Request permissions
  await _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(alert: true, badge: true, sound: true);
  tzdata.initializeTimeZones();
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
  final androidDetails = const AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'EdgeSync reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
  const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      scheduledDate.millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

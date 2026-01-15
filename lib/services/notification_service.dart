import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> requestPermissions() async {
    // Request notification permissions
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Request exact alarm permission (Android 12+)
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final bool? exactAlarmGranted = await androidImplementation.canScheduleExactNotifications();
      
      if (exactAlarmGranted != true) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
    
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    
    try {
      await _notifications.zonedSchedule(
        0,
        'Time to log your mood! 🌟',
        'How are you feeling today? Take a moment to reflect.',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily Mood Reminder',
            channelDescription: 'Daily reminder to log your mood',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('DEBUG: Error while planning: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_hour');
    await prefs.remove('reminder_minute');
  }

  Future<Map<String, int>?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour');
    final minute = prefs.getInt('reminder_minute');

    if (hour != null && minute != null) {
      return {'hour': hour, 'minute': minute};
    }
    return null;
  }

  Future<void> showInstantNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_notification',
      'Instant Notifications',
      channelDescription: 'Notifications shown immediately',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
}
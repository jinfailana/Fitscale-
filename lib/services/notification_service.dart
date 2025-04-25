import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Simple initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> showStepGoalNotification({
    required int steps,
    required int goal,
  }) async {
    if (!_isInitialized) await initialize();

    // Simple notification details without problematic features
    const androidDetails = AndroidNotificationDetails(
      'step_goals',
      'Step Goals',
      channelDescription: 'Notifications for step goal achievements',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final message = 'Amazing! You\'ve reached your goal of $goal steps with $steps steps today!';

    try {
      await _notifications.show(
        0,
        'Goal Reached! 🎉',
        message,
        details,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
} 
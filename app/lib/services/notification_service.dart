import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'calendar_repository.dart';

/// Payload value — tap opens [MetalRatesScreen].
const kMetalRatesNotificationRoute = 'metal_rates';

/// Payload value — tap opens [BudgetScreen].
const kBudgetNotificationRoute = 'budget';

/// Payload prefix — tap opens [PostDetailScreen] (`post:<id>`).
const kPostNotificationRoute = 'post';

/// FCM topics.
const kMetalRatesFcmTopic = 'metal_rates_updates';
const kPostsFcmTopic = 'posts_updates';

String postNotificationPayload(String postId) => '$kPostNotificationRoute:$postId';

const _postFcmNotificationId = 3001;
const _postsChannelId = 'posts';
const _postsChannelName = 'பதிவுகள்';
const _postsChannelDescription = 'புதிய பதிவு நினைவூட்டல்கள்';

Future<NotificationDetails> _buildPostNotificationDetails({
  required String title,
  required String body,
  String? imageUrl,
}) async {
  AndroidNotificationDetails androidDetails;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        androidDetails = AndroidNotificationDetails(
          _postsChannelId,
          _postsChannelName,
          channelDescription: _postsChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(response.bodyBytes),
            contentTitle: body.isNotEmpty ? title : null,
            summaryText: body.isNotEmpty ? body : null,
            hideExpandedLargeIcon: true,
          ),
        );
        return NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(),
        );
      }
    } catch (_) {
      // Fall back to text-only notification.
    }
  }

  androidDetails = AndroidNotificationDetails(
    _postsChannelId,
    _postsChannelName,
    channelDescription: _postsChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );
  return NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(),
  );
}

Future<void> _displayPostNotificationFromData(
  Map<String, dynamic> data, {
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final postId = data['post_id']?.toString() ?? '';
  if (postId.isEmpty) return;

  final title = data['title']?.toString() ?? 'புதிய பதிவு';
  final body = data['body']?.toString() ?? '';
  final imageUrl = data['image_url']?.toString();

  final activePlugin = plugin ?? FlutterLocalNotificationsPlugin();
  if (plugin == null) {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await activePlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  if (Platform.isAndroid) {
    final android = activePlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _postsChannelId,
        _postsChannelName,
        description: _postsChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  final details = await _buildPostNotificationDetails(
    title: title,
    body: body,
    imageUrl: imageUrl,
  );

  await activePlugin.show(
    id: _postFcmNotificationId,
    title: title,
    body: body.isNotEmpty ? body : null,
    notificationDetails: details,
    payload: postNotificationPayload(postId),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (message.data['route'] == kPostNotificationRoute) {
    await _displayPostNotificationFromData(message.data);
  }
}

/// Schedules daily morning notifications and handles FCM pushes.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _prefMorningEnabled = 'daily_morning_notification_enabled';
  static const _prefBudgetEnabled = 'daily_budget_notification_enabled';
  static const _prefMetalRatesEnabled = 'metal_rates_notification_enabled';

  static const _morningChannelId = 'daily_morning';
  static const _morningChannelName = 'காலை நினைவூட்டல்';
  static const _morningChannelDescription = 'தினசரி பஞ்சாங்கம் & ராசிபலன் நினைவூட்டல்';

  static const _budgetChannelId = 'budget_reminder';
  static const _budgetChannelName = 'வரவு செலவு நினைவூட்டல்';
  static const _budgetChannelDescription = 'தினசரி வரவு செலவு பதிவு நினைவூட்டல்';

  static const _metalChannelId = 'metal_rates';
  static const _metalChannelName = 'தங்கம் & வெள்ளி நிலவரம்';
  static const _metalChannelDescription = 'இன்றைய தங்கம் மற்றும் வெள்ளி விலை நினைவூட்டல்';

  static const _metalTitleTa = 'இன்றைய தங்கம் மற்றும் வெள்ளி நிலவரம்';
  static const _metalBodyTa = 'இன்றைய தங்கம் & வெள்ளி விலை பாருங்கள்';

  static const _morningHour = 7;
  static const _morningMinute = 0;
  static const _budgetHour = 20;
  static const _budgetMinute = 0;
  static const _daysAhead = 14;
  static const _morningBaseId = 1000;
  static const _budgetBaseId = 1500;
  static const _metalFcmNotificationId = 2001;

  static const _morningTitleTa = 'இன்றைய நாள்';
  static const _morningBodyFallbackTa = 'இன்றைய பஞ்சாங்கம் & ராசிபலன் பாருங்கள்!';
  static const _morningBodySuffixTa = 'இன்றைய ராசிபலன் பாருங்கள்!';

  static const _budgetTitleTa = 'வரவு செலவு';
  static const _budgetBodyTa = 'இன்றைய வரவு செலவுகளை குறிக்கும் நேரம்';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  void Function(String payload)? onNotificationTap;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_supported || _initialized) return;

    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationBackgroundTap,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _morningChannelId,
          _morningChannelName,
          description: _morningChannelDescription,
          importance: Importance.defaultImportance,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _budgetChannelId,
          _budgetChannelName,
          description: _budgetChannelDescription,
          importance: Importance.defaultImportance,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _metalChannelId,
          _metalChannelName,
          description: _metalChannelDescription,
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _postsChannelId,
          _postsChannelName,
          description: _postsChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundFcmMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmMessageOpened);

    _initialized = true;
  }

  static void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      instance.onNotificationTap?.call(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onLocalNotificationBackgroundTap(NotificationResponse response) {
    _onLocalNotificationTap(response);
  }

  Future<void> setupPushNotifications() async {
    if (!_supported) return;
    if (!_initialized) await initialize();

    final permitted = await _requestPermission();
    if (!permitted) return;

    if (await isMetalRatesEnabled) {
      await FirebaseMessaging.instance.subscribeToTopic(kMetalRatesFcmTopic);
    }
    await FirebaseMessaging.instance.subscribeToTopic(kPostsFcmTopic);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleFcmData(initial.data);
    }
  }

  Future<bool> get isMorningEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefMorningEnabled) ?? true;
  }

  Future<bool> get isBudgetEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefBudgetEnabled) ?? true;
  }

  Future<bool> get isMetalRatesEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefMetalRatesEnabled) ?? true;
  }

  Future<void> setMorningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMorningEnabled, enabled);
    if (!enabled) {
      await _cancelMorningNotifications();
    }
  }

  Future<void> setBudgetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBudgetEnabled, enabled);
    if (!enabled) {
      await _cancelBudgetNotifications();
    }
  }

  Future<void> setMetalRatesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefMetalRatesEnabled, enabled);
    if (enabled) {
      await FirebaseMessaging.instance.subscribeToTopic(kMetalRatesFcmTopic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(kMetalRatesFcmTopic);
    }
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await _cancelMorningNotifications();
    await _cancelBudgetNotifications();
  }

  Future<void> handleLaunchNotification() async {
    if (!_supported) return;
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        onNotificationTap?.call(payload);
      }
    }
  }

  Future<void> _cancelMorningNotifications() async {
    for (var offset = 0; offset < _daysAhead; offset++) {
      await _plugin.cancel(id: _morningBaseId + offset);
    }
  }

  Future<void> _cancelBudgetNotifications() async {
    for (var offset = 0; offset < _daysAhead; offset++) {
      await _plugin.cancel(id: _budgetBaseId + offset);
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (Platform.isIOS) {
      final ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      final fcmGranted = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return (granted ?? false) &&
          (fcmGranted.authorizationStatus == AuthorizationStatus.authorized ||
              fcmGranted.authorizationStatus == AuthorizationStatus.provisional);
    }
    return true;
  }

  Future<void> scheduleDailyMorningNotifications(CalendarRepository repository) async {
    if (!_supported) return;
    if (!_initialized) await initialize();
    if (!await isMorningEnabled) return;

    final permitted = await _requestPermission();
    if (!permitted) return;

    await _cancelMorningNotifications();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < _daysAhead; offset++) {
      final date = today.add(Duration(days: offset));
      final scheduled = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        _morningHour,
        _morningMinute,
      );
      if (!scheduled.isAfter(now)) continue;

      final body = await _bodyForDate(repository, date);

      await _plugin.zonedSchedule(
        id: _morningBaseId + offset,
        title: _morningTitleTa,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _morningChannelId,
            _morningChannelName,
            channelDescription: _morningChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'daily_morning',
      );
    }
  }

  Future<void> scheduleDailyBudgetNotifications() async {
    if (!_supported) return;
    if (!_initialized) await initialize();
    if (!await isBudgetEnabled) return;

    final permitted = await _requestPermission();
    if (!permitted) return;

    await _cancelBudgetNotifications();

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < _daysAhead; offset++) {
      final date = today.add(Duration(days: offset));
      final scheduled = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        _budgetHour,
        _budgetMinute,
      );
      if (!scheduled.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _budgetBaseId + offset,
        title: _budgetTitleTa,
        body: _budgetBodyTa,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _budgetChannelId,
            _budgetChannelName,
            channelDescription: _budgetChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: kBudgetNotificationRoute,
      );
    }
  }

  void _onForegroundFcmMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route == kMetalRatesNotificationRoute) {
      _showMetalRatesForeground(message);
    } else if (route == kPostNotificationRoute) {
      _showPostForeground(message);
    }
  }

  void _showMetalRatesForeground(RemoteMessage message) {
    _plugin.show(
      id: _metalFcmNotificationId,
      title: message.notification?.title ?? _metalTitleTa,
      body: message.notification?.body ?? _metalBodyTa,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _metalChannelId,
          _metalChannelName,
          channelDescription: _metalChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: kMetalRatesNotificationRoute,
    );
  }

  void _showPostForeground(RemoteMessage message) {
    unawaited(_displayPostNotificationFromData(message.data, plugin: _plugin));
  }

  void _onFcmMessageOpened(RemoteMessage message) {
    _handleFcmData(message.data);
  }

  void _handleFcmData(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route == kMetalRatesNotificationRoute) {
      onNotificationTap?.call(kMetalRatesNotificationRoute);
      return;
    }
    if (route == kPostNotificationRoute) {
      final postId = data['post_id']?.toString();
      if (postId != null && postId.isNotEmpty) {
        onNotificationTap?.call(postNotificationPayload(postId));
      }
    }
  }

  Future<String> _bodyForDate(CalendarRepository repository, DateTime date) async {
    try {
      final home = await repository.getHome(date: date);
      final banner = home.bannerLineTa.trim();
      if (banner.isNotEmpty) {
        return '$banner · $_morningBodySuffixTa';
      }
    } catch (_) {
      // Offline / missing calendar row — use generic Tamil message.
    }
    return _morningBodyFallbackTa;
  }
}

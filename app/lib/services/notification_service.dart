import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'calendar_repository.dart';

/// Payload value — tap opens [MetalRatesScreen].
const kMetalRatesNotificationRoute = 'metal_rates';

/// Payload value — tap opens [BudgetScreen].
const kBudgetNotificationRoute = 'budget';

/// Payload value — tap opens the இன்று tab on [HomeScreen].
const kIndruNotificationRoute = 'indru';

/// Payload prefix — tap opens [PostDetailScreen] (`post:<id>`).
const kPostNotificationRoute = 'post';

/// FCM topics.
const kMetalRatesFcmTopic = 'metal_rates_updates';
const kPostsFcmTopic = 'posts_updates';
const kIndruFcmTopic = 'indru_updates';

String postNotificationPayload(String postId) => '$kPostNotificationRoute:$postId';

const _postFcmNotificationId = 3001;
const _indruFcmNotificationId = 4001;
const _metalFcmNotificationId = 2001;
const _postsChannelId = 'posts';
const _postsChannelName = 'பதிவுகள்';
const _postsChannelDescription = 'புதிய பதிவு நினைவூட்டல்கள்';
const _indruChannelId = 'indru';
const _indruChannelName = 'இன்று';
const _indruChannelDescription = 'இன்று தினசரி தகவல் நினைவூட்டல்கள்';
const _indruTitleFallbackTa = 'இன்று — தினசரி தகவல்கள்';
const _metalChannelId = 'metal_rates';
const _metalChannelName = 'தங்கம் & வெள்ளி நிலவரம்';
const _metalChannelDescription = 'இன்றைய தங்கம் மற்றும் வெள்ளி விலை நினைவூட்டல்';
const _metalTitleTa = 'இன்றைய தங்கம் மற்றும் வெள்ளி நிலவரம்';
const _metalBodyTa = 'இன்றைய தங்கம் & வெள்ளி விலை பாருங்கள்';
const _prefPendingNotificationPayload = 'pending_notification_payload';
const _prefNotificationSystemPromptAttempted =
    'notification_system_prompt_attempted';

@pragma('vm:entry-point')
void onNotificationBackgroundResponseReceived(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  SharedPreferences.getInstance().then((prefs) {
    prefs.setString(_prefPendingNotificationPayload, payload);
  });
}

Future<void> _persistPendingNotificationPayload(String payload) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefPendingNotificationPayload, payload);
}

Future<String?> _consumePersistedNotificationPayload() async {
  final prefs = await SharedPreferences.getInstance();
  final payload = prefs.getString(_prefPendingNotificationPayload);
  if (payload != null) {
    await prefs.remove(_prefPendingNotificationPayload);
  }
  return payload;
}

Future<void> _initLocalNotificationsPlugin(FlutterLocalNotificationsPlugin plugin) async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: NotificationService.onNotificationResponseReceived,
    onDidReceiveBackgroundNotificationResponse: onNotificationBackgroundResponseReceived,
  );
}

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

Future<NotificationDetails> _buildIndruNotificationDetails({
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
          _indruChannelId,
          _indruChannelName,
          channelDescription: _indruChannelDescription,
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
    _indruChannelId,
    _indruChannelName,
    channelDescription: _indruChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );
  return NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(),
  );
}

Future<void> _displayIndruNotificationFromData(
  Map<String, dynamic> data, {
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final title = data['title']?.toString() ?? _indruTitleFallbackTa;
  final body = data['body']?.toString() ?? '';
  final imageUrl = data['image_url']?.toString();

  final activePlugin = plugin ?? FlutterLocalNotificationsPlugin();
  if (plugin == null) {
    await _initLocalNotificationsPlugin(activePlugin);
  }

  if (Platform.isAndroid) {
    final android = activePlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _indruChannelId,
        _indruChannelName,
        description: _indruChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  final details = await _buildIndruNotificationDetails(
    title: title,
    body: body,
    imageUrl: imageUrl,
  );

  await activePlugin.show(
    id: _indruFcmNotificationId,
    title: title,
    body: body.isNotEmpty ? body : null,
    notificationDetails: details,
    payload: kIndruNotificationRoute,
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
    await _initLocalNotificationsPlugin(activePlugin);
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

Future<void> _displayMetalRatesNotificationFromData(
  Map<String, dynamic> data, {
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final title = data['title']?.toString() ?? _metalTitleTa;
  final body = data['body']?.toString() ?? _metalBodyTa;

  final activePlugin = plugin ?? FlutterLocalNotificationsPlugin();
  if (plugin == null) {
    await _initLocalNotificationsPlugin(activePlugin);
  }

  if (Platform.isAndroid) {
    final android = activePlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _metalChannelId,
        _metalChannelName,
        description: _metalChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  await activePlugin.show(
    id: _metalFcmNotificationId,
    title: title,
    body: body,
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final route = message.data['route']?.toString();
  if (route == kPostNotificationRoute) {
    await _displayPostNotificationFromData(message.data);
  } else if (route == kIndruNotificationRoute) {
    await _displayIndruNotificationFromData(message.data);
  } else if (route == kMetalRatesNotificationRoute) {
    await _displayMetalRatesNotificationFromData(message.data);
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

  static const _morningHour = 7;
  static const _morningMinute = 0;
  static const _budgetHour = 20;
  static const _budgetMinute = 0;
  static const _daysAhead = 14;
  static const _morningBaseId = 1000;
  static const _budgetBaseId = 1500;

  static const _morningTitleTa = 'இன்றைய நாள்';
  static const _morningBodyFallbackTa = 'இன்றைய பஞ்சாங்கம் & ராசிபலன் பாருங்கள்!';
  static const _morningBodySuffixTa = 'இன்றைய ராசிபலன் பாருங்கள்!';

  static const _budgetTitleTa = 'வரவு செலவு';
  static const _budgetBodyTa = 'இன்றைய வரவு செலவுகளை குறிக்கும் நேரம்';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool Function(String payload)? onNotificationTap;

  String? _pendingNotificationPayload;
  bool _updateReadyForNavigation = false;
  bool _homeReadyForNavigation = false;

  bool get isReadyForNavigation => _updateReadyForNavigation && _homeReadyForNavigation;

  void markUpdateReadyForNavigation() {
    _updateReadyForNavigation = true;
    _tryOpenPendingNavigation();
  }

  void markHomeReadyForNavigation() {
    _homeReadyForNavigation = true;
    _tryOpenPendingNavigation();
  }

  void _tryOpenPendingNavigation() {
    if (!isReadyForNavigation) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      processPendingLaunchNavigation();
    });
  }

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
      onDidReceiveNotificationResponse: NotificationService.onNotificationResponseReceived,
      onDidReceiveBackgroundNotificationResponse: onNotificationBackgroundResponseReceived,
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
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _indruChannelId,
          _indruChannelName,
          description: _indruChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundFcmMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmMessageOpened);

    _initialized = true;
  }

  static void onNotificationResponseReceived(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      instance._dispatchNotificationTap(payload);
    }
  }

  Future<void> setupPushNotifications() async {
    if (!_supported) return;
    if (!_initialized) await initialize();

    final permitted = await _hasNotificationPermission();
    if (!permitted) return;

    if (await isMetalRatesEnabled) {
      await FirebaseMessaging.instance.subscribeToTopic(kMetalRatesFcmTopic);
    }
    await FirebaseMessaging.instance.subscribeToTopic(kPostsFcmTopic);
    await FirebaseMessaging.instance.subscribeToTopic(kIndruFcmTopic);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleFcmData(initial.data);
    }
  }

  /// Call once update check is done and home/onboarding has finished.
  Future<void> processPendingLaunchNavigation() async {
    await handleLaunchNotification();
    final stored = await _consumePersistedNotificationPayload();
    if (stored != null) {
      _pendingNotificationPayload = stored;
    }
    _flushPendingNotificationTap();
  }

  void _dispatchNotificationTap(String payload) {
    _pendingNotificationPayload = payload;
    unawaited(_persistPendingNotificationPayload(payload));
    _flushPendingNotificationTap();
  }

  void _flushPendingNotificationTap() {
    final payload = _pendingNotificationPayload;
    if (payload == null) return;
    final handler = onNotificationTap;
    if (handler == null) return;
    if (handler(payload)) {
      _pendingNotificationPayload = null;
      unawaited(_consumePersistedNotificationPayload());
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
    } else {
      await scheduleDailyBudgetNotifications();
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
        _dispatchNotificationTap(payload);
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

  Future<bool> _hasNotificationPermission() async {
    if (!_supported) return true;
    if (Platform.isAndroid) {
      return Permission.notification.status.isGranted;
    }
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<bool> hasNotificationPermission() => _hasNotificationPermission();

  Future<bool> hasSystemPromptBeenAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotificationSystemPromptAttempted) ?? false;
  }

  /// Ask notification permission intentionally from UI flow (onboarding/home).
  /// This avoids prompting during splash/startup.
  Future<bool> requestPermissionFromUser({
    CalendarRepository? repository,
  }) async {
    if (!_supported) return true;
    if (!_initialized) await initialize();
    final alreadyGranted = await _hasNotificationPermission();

    if (alreadyGranted) {
      if (repository != null) {
        await scheduleAllDailyNotifications(repository);
      }
      await setupPushNotifications();
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotificationSystemPromptAttempted, true);
    final granted = await _requestPermission();
    if (!granted) return false;

    if (repository != null) {
      await scheduleAllDailyNotifications(repository);
    }
    await setupPushNotifications();
    return true;
  }

  Future<void> scheduleAllDailyNotifications(CalendarRepository repository) async {
    await scheduleDailyMorningNotifications(repository);
    await scheduleDailyBudgetNotifications();
  }

  Future<void> scheduleDailyMorningNotifications(CalendarRepository repository) async {
    if (!_supported) return;
    if (!_initialized) await initialize();
    if (!await isMorningEnabled) return;

    final permitted = await _hasNotificationPermission();
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

    final permitted = await _hasNotificationPermission();
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
    final route = message.data['route']?.toString();
    if (route == kMetalRatesNotificationRoute) {
      unawaited(_displayMetalRatesNotificationFromData(message.data, plugin: _plugin));
    } else if (route == kPostNotificationRoute) {
      _showPostForeground(message);
    } else if (route == kIndruNotificationRoute) {
      _showIndruForeground(message);
    }
  }

  void _showIndruForeground(RemoteMessage message) {
    unawaited(_displayIndruNotificationFromData(message.data, plugin: _plugin));
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
      _dispatchNotificationTap(kMetalRatesNotificationRoute);
      return;
    }
    if (route == kIndruNotificationRoute) {
      _dispatchNotificationTap(kIndruNotificationRoute);
      return;
    }
    if (route == kPostNotificationRoute) {
      final postId = data['post_id']?.toString();
      if (postId != null && postId.isNotEmpty) {
        _dispatchNotificationTap(postNotificationPayload(postId));
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

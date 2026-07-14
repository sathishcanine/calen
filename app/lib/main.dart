import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_config.dart';
import 'models/app_update_config.dart';
import 'screens/home_screen.dart';
import 'screens/metal_rates_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/temples/temples_screen.dart';
import 'services/ad_service.dart';
import 'services/calendar_repository.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_entry.dart';
import 'widgets/force_update_overlay.dart';

final navigatorKey = GlobalKey<NavigatorState>();

CalendarRepository? _appRepository;

Future<void> main() async {
  // Binding + runApp must share the same zone (avoids debugCheckZone crashes).
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Use bundled fonts only — avoids fatal crashes when fonts.gstatic.com is unreachable.
    GoogleFonts.config.allowRuntimeFetching = false;

    // Register once, before runApp (Firebase requirement).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Keep startup non-blocking so slow device/plugin init never freezes
    // the native launch screen before first Flutter frame is rendered.
    unawaited(FirebaseService.instance.initialize());
    unawaited(AdService.instance.initialize());
    unawaited(NotificationService.instance.initialize());

    final repository = await CalendarRepository.create();
    _appRepository = repository;
    NotificationService.instance.onNotificationTap = _handleNotificationTap;
    runApp(TamilarCalendarApp(repository: repository));
  }, (error, stack) {
    FirebaseService.instance.recordError(error, stack, fatal: false);
  });
}

bool _handleNotificationTap(String payload) {
  if (!NotificationService.instance.isReadyForNavigation ||
      _appRepository == null ||
      navigatorKey.currentState == null) {
    return false;
  }
  try {
    _openFromNotification(payload);
  } catch (_) {
    // Never crash on notification tap routing.
  }
  return true;
}

void _openFromNotification(String payload) {
  final repository = _appRepository;
  if (repository == null) return;

  void navigate(Widget screen) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  if (payload == kMetalRatesNotificationRoute) {
    navigate(MetalRatesScreen(repository: repository));
    return;
  }

  if (payload == kHomeNotificationRoute ||
      payload == kDailyMorningLocalPayload) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    HomeScreen.switchToTab?.call(HomeScreen.homeTabIndex);
    return;
  }

  if (payload == kBudgetNotificationRoute) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    HomeScreen.switchToTab?.call(HomeScreen.budgetTabIndex);
    return;
  }

  if (payload == kIndruNotificationRoute) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    HomeScreen.switchToTab?.call(HomeScreen.indruTabIndex);
    return;
  }

  if (payload.startsWith('$kPostNotificationRoute:')) {
    final postId = payload.substring(kPostNotificationRoute.length + 1);
    if (postId.isNotEmpty) {
      navigate(PostDetailScreen(repository: repository, postId: postId));
    }
    return;
  }

  if (payload.startsWith('$kTempleNotificationRoute:')) {
    final slug = payload.substring(kTempleNotificationRoute.length + 1);
    if (slug.isNotEmpty) {
      navigate(TempleDetailLoaderScreen(repository: repository, slug: slug));
    }
  }
}

class TamilarCalendarApp extends StatefulWidget {
  const TamilarCalendarApp({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<TamilarCalendarApp> createState() => _TamilarCalendarAppState();
}

class _TamilarCalendarAppState extends State<TamilarCalendarApp> {
  AppUpdateConfig? _requiredUpdate;
  bool _checkingUpdate = true;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final config = await RemoteConfigService.instance.checkForRequiredUpdate();
      if (!mounted) return;
      setState(() {
        _requiredUpdate = config;
        _checkingUpdate = false;
      });
      if (_requiredUpdate == null) {
        NotificationService.instance.markUpdateReadyForNavigation();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requiredUpdate = null;
        _checkingUpdate = false;
      });
      NotificationService.instance.markUpdateReadyForNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analytics = FirebaseService.instance.analytics;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.offlineMode
          ? 'Murugan Tamil Calendar - தமிழ் (ஆஃப்லைன்)'
          : 'Murugan Tamil Calendar - தமிழ்',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: analytics == null
          ? const []
          : [FirebaseAnalyticsObserver(analytics: analytics)],
      builder: (context, child) {
        if (_checkingUpdate) {
          return const _UpdateCheckSplash();
        }
        if (_requiredUpdate != null) {
          return ForceUpdateOverlay(config: _requiredUpdate!);
        }
        return child ?? const SizedBox.shrink();
      },
      home: AppEntry(repository: widget.repository),
    );
  }
}

class _UpdateCheckSplash extends StatelessWidget {
  const _UpdateCheckSplash();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: AppColors.cream,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

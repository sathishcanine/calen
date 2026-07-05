import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'models/app_update_config.dart';
import 'screens/budget/budget_screen.dart';
import 'screens/metal_rates_screen.dart';
import 'screens/post_detail_screen.dart';
import 'services/ad_service.dart';
import 'services/calendar_repository.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_entry.dart';
import 'widgets/force_update_overlay.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.instance.initialize();
  await AdService.instance.initialize();
  await NotificationService.instance.initialize();

  runZonedGuarded(
    () async {
      final repository = await CalendarRepository.create();
      NotificationService.instance.onNotificationTap = (payload) {
        _openFromNotification(payload, repository);
      };
      await NotificationService.instance.scheduleDailyMorningNotifications(repository);
      await NotificationService.instance.setupPushNotifications();
      runApp(TamilarCalendarApp(repository: repository));
    },
    (error, stack) {
      FirebaseService.instance.recordError(error, stack, fatal: true);
    },
  );
}

void _openFromNotification(String payload, CalendarRepository repository) {
  void navigate(Widget screen) {
    if (navigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
      });
    } else {
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  if (payload == kMetalRatesNotificationRoute) {
    navigate(MetalRatesScreen(repository: repository));
    return;
  }

  if (payload == kBudgetNotificationRoute) {
    navigate(const BudgetScreen());
    return;
  }

  if (payload.startsWith('$kPostNotificationRoute:')) {
    final postId = payload.substring(kPostNotificationRoute.length + 1);
    if (postId.isNotEmpty) {
      navigate(PostDetailScreen(repository: repository, postId: postId));
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
    final config = await RemoteConfigService.instance.checkForRequiredUpdate();
    if (!mounted) return;
    setState(() {
      _requiredUpdate = config;
      _checkingUpdate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = FirebaseService.instance.analytics;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.offlineMode
          ? 'Tamil Calender - A-Z தமிழ் (ஆஃப்லைன்)'
          : 'Tamil Calender - A-Z தமிழ்',
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

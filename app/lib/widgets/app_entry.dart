import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/app_intro_onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../services/app_onboarding_service.dart';
import '../services/calendar_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Routes first-time users through feature intro, then opens home.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _introDone;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await AppOnboardingService.instance.hasCompletedIntro();
    if (!mounted) return;
    setState(() {
      _introDone = done;
      _checking = false;
    });
    if (done == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onHomeReady());
    }
  }

  Future<void> _completeIntro() async {
    await AppOnboardingService.instance.markIntroCompleted();
    if (!mounted) return;
    setState(() => _introDone = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onHomeReady());
  }

  void _onHomeReady() {
    NotificationService.instance.markHomeReadyForNavigation();
    unawaited(_promptNotificationsIfNeeded());
  }

  Future<void> _promptNotificationsIfNeeded() async {
    final hasPermission = await NotificationService.instance.hasNotificationPermission();
    if (!mounted || hasPermission) {
      if (hasPermission) {
        await NotificationService.instance.requestPermissionFromUser(
          repository: widget.repository,
        );
      }
      return;
    }

    final firstPromptDone =
        await NotificationService.instance.hasSystemPromptBeenAttempted();
    if (!mounted) return;
    if (!firstPromptDone) {
      await NotificationService.instance.requestPermissionFromUser(
        repository: widget.repository,
      );
      return;
    }

    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('அறிவிப்புகளை இயக்கவா?'),
        content: const Text(
          'தினசரி இன்று, தங்கம்-வெள்ளி விலை, மற்றும் வரவு செலவு நினைவூட்டல்களுக்கு Notifications அனுமதி தேவை.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('இயக்கு'),
          ),
        ],
      ),
    );

    if (!mounted || enable != true) return;
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }

    if (_introDone != true) {
      return AppIntroOnboardingScreen(onComplete: _completeIntro);
    }

    return HomeScreen(repository: widget.repository);
  }
}

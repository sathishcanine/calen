import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../services/calendar_repository.dart';

/// Opens home directly — city selection via top-right location button.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(repository: repository);
  }
}

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/calendar_repository.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TamilarCalendarApp(repository: CalendarRepository()));
}

class TamilarCalendarApp extends StatelessWidget {
  const TamilarCalendarApp({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'தமிழர் உலகம் காலண்டர்',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(repository: repository),
    );
  }
}

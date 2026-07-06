import 'package:flutter_test/flutter_test.dart';
import 'package:tamilar_calendar/main.dart';
import 'package:tamilar_calendar/services/calendar_repository.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    await tester.pumpWidget(
      TamilarCalendarApp(repository: CalendarRepository()),
    );
    expect(find.textContaining('Murugan Tamil Calendar'), findsWidgets);
  });
}

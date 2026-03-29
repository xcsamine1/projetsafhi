import 'package:flutter_test/flutter_test.dart';
import 'package:attendance/main.dart';

void main() {
  testWidgets('App starts on login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    await tester.pump();

    // In dummy mode the app shows the login screen first
    expect(find.text('Connexion Professeur'), findsOneWidget);
  });
}

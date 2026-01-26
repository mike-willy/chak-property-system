import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/presentation/screens/auth/pages/role_selection_page.dart';
import 'package:mobile_app/presentation/screens/auth/pages/login_page.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  testWidgets('RoleSelectionPage renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionPage(),
      ),
    );

    // Verify finding the two cards
    expect(find.text('I am a Tenant'), findsOneWidget);
    expect(find.text('I am a Landlord'), findsOneWidget);
  });

  // Note: Testing navigation usually requires a navigator observer or integration test.
  // We will trust the manual verification or simplified widget structure for now.
}

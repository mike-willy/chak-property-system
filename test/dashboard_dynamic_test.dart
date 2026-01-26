import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/presentation/screens/pages/dashboard_page.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/tenant_provider.dart';
import 'package:mobile_app/providers/property_provider.dart';
import 'package:mobile_app/providers/application_provider.dart';
import 'package:mobile_app/data/models/user_model.dart';
import 'package:mobile_app/data/models/tenant_model.dart';
import 'package:mobile_app/data/models/application_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

// Mocks
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  bool get isTenant => super.noSuchMethod(Invocation.getter(#isTenant), returnValue: false);
  @override
  bool get isLandlord => super.noSuchMethod(Invocation.getter(#isLandlord), returnValue: false);
  @override
  bool get isAdmin => super.noSuchMethod(Invocation.getter(#isAdmin), returnValue: false);
  @override
  UserModel? get userProfile => super.noSuchMethod(Invocation.getter(#userProfile));
  @override
  fb.User? get firebaseUser => super.noSuchMethod(Invocation.getter(#firebaseUser));
}

class MockTenantProvider extends Mock implements TenantProvider {
  @override
  TenantModel? get tenant => super.noSuchMethod(Invocation.getter(#tenant));
  @override
  bool get isLoading => super.noSuchMethod(Invocation.getter(#isLoading), returnValue: false);
  @override
  Future<void> loadTenantData() => super.noSuchMethod(Invocation.method(#loadTenantData, []), returnValue: Future.value());
}

class MockPropertyProvider extends Mock implements PropertyProvider {
  @override
  List<dynamic> get properties => super.noSuchMethod(Invocation.getter(#properties), returnValue: []);
  @override
  Future<void> loadProperties() => super.noSuchMethod(Invocation.method(#loadProperties, []), returnValue: Future.value());
  @override
  Future<void> loadStats() => super.noSuchMethod(Invocation.method(#loadStats, []), returnValue: Future.value());
}

class MockApplicationProvider extends Mock implements ApplicationProvider {
  @override
  List<dynamic> get applications => super.noSuchMethod(Invocation.getter(#applications), returnValue: []);

  @override
  Stream<List<ApplicationModel>> getTenantApplicationsStream(String? userId) => 
      super.noSuchMethod(Invocation.method(#getTenantApplicationsStream, [userId]), 
      returnValue: Stream<List<ApplicationModel>>.value([]));
}

void main() {
  late MockAuthProvider mockAuth;
  late MockTenantProvider mockTenant;
  late MockPropertyProvider mockProperty;
  late MockApplicationProvider mockApplication;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockTenant = MockTenantProvider();
    mockProperty = MockPropertyProvider();
    mockApplication = MockApplicationProvider();

    // Default Stubs
    when(mockProperty.properties).thenReturn([]);
    when(mockProperty.loadProperties()).thenAnswer((_) async {});
    when(mockProperty.loadStats()).thenAnswer((_) async {});
    when(mockTenant.loadTenantData()).thenAnswer((_) async {});
    when(mockAuth.firebaseUser).thenReturn(null); // Default null unless specified
    when(mockAuth.userProfile).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
        ChangeNotifierProvider<TenantProvider>.value(value: mockTenant),
        ChangeNotifierProvider<PropertyProvider>.value(value: mockProperty),
        ChangeNotifierProvider<ApplicationProvider>.value(value: mockApplication),
      ],
      child: const MaterialApp(
        home: DashboardPage(),
      ),
    );
  }

  testWidgets('New Tenant (No Lease) sees Restricted Dashboard (Properties, Status, Profile)', (WidgetTester tester) async {
    // Arrange: Tenant logged in but NO lease (tenant == null)
    when(mockAuth.isTenant).thenReturn(true);
    when(mockAuth.isLandlord).thenReturn(false);
    when(mockAuth.isAdmin).thenReturn(false);
    // when(mockAuth.firebaseUser).thenReturn(MockUser()); // MockUser difficult to instantiate, leaving null might trigger logic bypass or use simple object if needed.
    // Actually DashboardPage checks firebaseUser != null to load data. 
    // We can skip data loading check for UI composition testing primarily.
    
    when(mockTenant.tenant).thenReturn(null); // No active lease

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 50)); // Trigger PostFrameCallback
    await tester.pump(const Duration(milliseconds: 50)); // Rebuild after setState
    await tester.pump(); // Just in case
    
    // Assert
    // Should see "Browse" (Properties)
    expect(find.text('Browse'), findsOneWidget);
    // Should see "Status" (Home)
    expect(find.text('Status'), findsOneWidget); 
    // Should see "Profile"
    expect(find.text('Profile'), findsOneWidget);

    // Should NOT see "Messages"
    expect(find.text('Messages'), findsNothing);
    // Should NOT see "Maint."
    expect(find.text('Maint.'), findsNothing);
  });

  testWidgets('Approved Tenant (With Lease) sees Full Dashboard', (WidgetTester tester) async {
    // Arrange: Tenant logged in AND has lease
    when(mockAuth.isTenant).thenReturn(true);
    when(mockAuth.isLandlord).thenReturn(false);
    when(mockAuth.isAdmin).thenReturn(false);
    
    // Mock a tenant object
    final dummyTenant = TenantModel(
        id: '1', userId: 'u1', propertyId: 'p1', unitId: 'u1', 
        status: TenantStatus.active, leaseStartDate: DateTime.now(), leaseEndDate: DateTime.now(),
        rentAmount: 1000, fullName: 'Test', email: 'test@test.com', phone: '123'
    );
    when(mockTenant.tenant).thenReturn(dummyTenant);

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    // Assert
    // Should see "Home"
    expect(find.text('Home'), findsOneWidget);
    // Should see "Rentals" (Properties)
    expect(find.text('Rentals'), findsOneWidget); 
    // Should see "Messages"
    expect(find.text('Messages'), findsOneWidget);
    // Should see "Maint."
    expect(find.text('Maint.'), findsOneWidget);
    // Should see "Profile"
    expect(find.text('Profile'), findsOneWidget);
  });
}

// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/property_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/application_provider.dart';

// Data Sources & Repositories
import 'data/datasources/remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/property_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/maintenance_repository.dart';
import 'data/repositories/application_repository.dart';
import 'data/repositories/tenant_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'providers/tenant_provider.dart';

// Screens
import 'presentation/screens/auth/widgets/auth_gate.dart';
import 'presentation/themes/app_theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print("Error initializing app: $e");
    print(stackTrace);
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Error initializing app: $e", textDirection: TextDirection.ltr),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Services
        Provider(create: (_) => FirebaseFirestore.instance),
        
        // Data Sources
        Provider(
          create: (context) => RemoteDataSource(
            context.read<FirebaseFirestore>(),
          ),
        ),
        
        // Repositories
        Provider(
          create: (context) => PropertyRepository(
            context.read<RemoteDataSource>(),
          ),
        ),
        Provider(
          create: (context) => AuthRepository(
            context.read<RemoteDataSource>(),
          ),
        ),
        Provider(
          create: (context) => NotificationRepository(
            context.read<RemoteDataSource>(),
          ),
        ),
        Provider(
          create: (context) => MessageRepository(
            firestore: context.read<FirebaseFirestore>(),
          ),
        ),
        Provider(
          create: (context) => MaintenanceRepository(
            context.read<RemoteDataSource>(),
          ),
        ),
        Provider(
          create: (context) => ApplicationRepository(),
        ),
        Provider(
          create: (context) => TenantRepository(),
        ),
        Provider(
          create: (context) => PaymentRepository(),
        ),
        
        // Providers
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(
            context.read<NotificationRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MessageProvider(
            messageRepository: context.read<MessageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ApplicationProvider(
            context.read<ApplicationRepository>(),
            context.read<TenantRepository>(),
          ),
        ),
        
        // Tenant Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, TenantProvider>(
          create: (context) => TenantProvider(
            context.read<TenantRepository>(),
            context.read<PaymentRepository>(),
            context.read<PropertyRepository>(),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) {
             previous!.update(auth);
             return previous;
          },
        ),
        
        // Property Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, PropertyProvider>(
          create: (context) => PropertyProvider(
            context.read<PropertyRepository>(),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) {
            previous!.update(auth);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider3<AuthProvider, TenantProvider, PropertyProvider, MaintenanceProvider>(
          create: (context) => MaintenanceProvider(
            context.read<MaintenanceRepository>(),
            context.read<AuthProvider>(),
            context.read<TenantProvider>(),
            context.read<PropertyProvider>(),
          ),
          update: (context, auth, tenant, property, previous) {
            previous!.update(auth, tenant, property);
            return previous;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Property Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
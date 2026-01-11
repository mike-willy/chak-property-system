
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/property_provider.dart';
import 'data/datasources/remote_datasource.dart';
import 'package:mobile_app/presentation/screens/pages/dashboard_page.dart';
import 'data/repositories/property_repository.dart';
import 'presentation/screens/properties/pages/property_list_page.dart';
import 'presentation/screens/properties/pages/property_list_page.dart';
import 'presentation/themes/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';

import 'firebase_options.dart';

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
        Provider(create: (_) => FirebaseFirestore.instance),
        Provider(
          create: (context) => RemoteDataSource(
            context.read<FirebaseFirestore>(),
          ),
        ),
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
        ChangeNotifierProxyProvider<AuthProvider, PropertyProvider>(
          create: (context) => PropertyProvider(
            context.read<PropertyRepository>(),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => PropertyProvider(
            context.read<PropertyRepository>(),
            auth,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Property Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: PropertyListPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

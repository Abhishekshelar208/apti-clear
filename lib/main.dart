import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DMCEAptiLabApp());
}

class DMCEAptiLabApp extends StatelessWidget {
  const DMCEAptiLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DMCE AptiLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Responsive Light/Dark theme mechanism
      initialRoute: AppRoutes.authCheck,
      routes: AppRoutes.routes,
    );
  }
}

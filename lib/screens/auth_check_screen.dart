import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash effect and to ensure async works smoothly
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('auth_role');
    final id = prefs.getString('auth_id');

    if (role != null) {
      if (role == 'student' && id != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard, arguments: id);
        return;
      } else if (role == 'teacher') {
        Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
        return;
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      }
    }

    // Default to Login
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: theme.primaryColor),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

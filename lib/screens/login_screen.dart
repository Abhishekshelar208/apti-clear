import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Fetch student data by ID
      final snapshot = await _database.child('students').child(studentId).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final storedPassword = data['password']; // Note: Should be hashed in production

        if (storedPassword == password) {
          // 2. Success: Save Session & Navigate
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_role', 'student');
          await prefs.setString('auth_id', studentId);

          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              AppRoutes.dashboard,
              arguments: studentId,
            );
          }
        } else {
          _showErrorDialog('Invalid password. Please try again.');
        }
      } else {
        _showErrorDialog('Student ID not found. Please register.');
      }
    } catch (e) {
      _showErrorDialog('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Icon
                  Icon(
                    Icons.school,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  
                  // App Title
                  Text(
                    'DMCE AptiLab',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                   Text(
                    'Student Login',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Student ID Input
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your Student ID';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Create Account'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Teacher Login Link
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.teacherLogin);
                    },
                    icon: Icon(Icons.admin_panel_settings_outlined, size: 18, color: theme.disabledColor),
                    label: Text(
                      'Teacher Login',
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ),
                  SizedBox(height: 50,),
                  Text("Version: 1.0.4"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  State<TeacherRegistrationScreen> createState() => _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _database = FirebaseDatabase.instance.ref();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Check if ID already exists
      final snapshot = await _database.child('teachers').child(id).get();
      if (snapshot.exists) {
        _showError('Teacher ID "$id" already exists. Please login.');
        return;
      }

      // 2. Create Account
      await _database.child('teachers').child(id).set({
        'name': name,
        'password': password, // Note: Hash in production
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 3. Auto-Login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_role', 'teacher');
      await prefs.setString('auth_id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
      }

    } catch (e) {
      _showError('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Teacher Registration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Icon(Icons.person_add, size: 64, color: theme.primaryColor),
                   const SizedBox(height: 24),
                   
                   // Name
                   TextFormField(
                     controller: _nameController,
                     decoration: const InputDecoration(
                       labelText: 'Full Name',
                       prefixIcon: Icon(Icons.person),
                       border: OutlineInputBorder(),
                     ),
                     validator: (v) => v!.isEmpty ? 'Name is required' : null,
                   ),
                   const SizedBox(height: 16),
                   
                   // ID
                   TextFormField(
                     controller: _idController,
                     decoration: const InputDecoration(
                       labelText: 'Teacher ID (e.g., EMP01)',
                       prefixIcon: Icon(Icons.badge),
                       border: OutlineInputBorder(),
                     ),
                     validator: (v) => v!.isEmpty ? 'ID is required' : null,
                   ),
                   const SizedBox(height: 16),
                   
                   // Password
                   TextFormField(
                     controller: _passwordController,
                     obscureText: _obscurePassword,
                     decoration: InputDecoration(
                       labelText: 'Password',
                       prefixIcon: const Icon(Icons.lock),
                       border: const OutlineInputBorder(),
                       suffixIcon: IconButton(
                         icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                         onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                       )
                     ),
                     validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                   ),
                   const SizedBox(height: 32),

                   // Submit
                   SizedBox(
                     height: 50,
                     child: ElevatedButton(
                       onPressed: _isLoading ? null : _registerTeacher,
                       child: _isLoading 
                         ? const CircularProgressIndicator(color: Colors.white)
                         : const Text('Create Account', style: TextStyle(fontSize: 16)),
                     ),
                   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dropdown Values
  String? _selectedYear;
  String? _selectedBranch;
  String? _selectedDivision;

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Dropdown Options
  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final List<String> _branches = ['CO', 'IT', 'AIDS'];
  final List<String> _divisions = ['A', 'B', 'C']; // Assuming generic divisions or strict A, B, C

  @override
  void dispose() {
    _fullNameController.dispose();
    _rollNoController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final studentId = _studentIdController.text.trim();
    final studentRef = _database.child('students').child(studentId);

    try {
      // 1. Check if student ID already exists
      final snapshot = await studentRef.get();

      if (snapshot.exists) {
        _showErrorDialog('Student ID already exists. Please login or use a different ID.');
      } else {
        // 2. Create new student record
        await studentRef.set({
          'fullName': _fullNameController.text.trim(),
          'year': _selectedYear,
          'branch': _selectedBranch,
          'division': _selectedDivision,
          'rollNo': _rollNoController.text.trim(),
          'studentId': studentId,
          'password': _passwordController.text, // In a real app, hash this!
          'createdAt': DateTime.now().toIso8601String(),
        });

        // 3. Navigate to Login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } catch (e) {
      _showErrorDialog('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
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
      appBar: AppBar(
        title: const Text('Student Registration'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Icon(
                    Icons.person_add_outlined,
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Student ID
                  TextFormField(
                    controller: _studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID (Unique)',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a Student ID' : null,
                  ),
                  const SizedBox(height: 16),

                  // Row for Year & Branch
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedBranch,
                          decoration: const InputDecoration(
                            labelText: 'Branch',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _selectedBranch = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row for Division & Roll No
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDivision,
                          decoration: const InputDecoration(
                            labelText: 'Div',
                            prefixIcon: Icon(Icons.class_outlined),
                          ),
                          items: _divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setState(() => _selectedDivision = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _rollNoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Roll No',
                            prefixIcon: Icon(Icons.numbers_outlined),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 chars' : null,
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerStudent,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Create Account', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login Here'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

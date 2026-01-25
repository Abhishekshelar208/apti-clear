import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _database = FirebaseDatabase.instance.ref();
  
  // Teacher Selection
  String? _selectedTeacherId;
  List<String> _teacherIds = [];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isFetchingTeachers = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherIds();
  }

  Future<void> _fetchTeacherIds() async {
    try {
      final snapshot = await _database.child('teachers').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Extract keys
        final ids = data.keys.map((k) => k.toString()).toList();
        ids.sort();
        
        if (mounted) {
           setState(() {
             _teacherIds = ids;
             _isFetchingTeachers = false;
           });
        }
      } else {
        if (mounted) setState(() => _isFetchingTeachers = false);
      }
    } catch (e) {
      debugPrint("Error loading teachers: $e");
      if (mounted) setState(() => _isFetchingTeachers = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTeacherId == null) {
      _showError('Please select a Teacher ID');
      return;
    }

    setState(() => _isLoading = true);
    final password = _passwordController.text;

    try {
      final snapshot = await _database.child('teachers').child(_selectedTeacherId!).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final storedPassword = data['password'];

        if (storedPassword == password) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_role', 'teacher');
          await prefs.setString('auth_id', _selectedTeacherId!);

          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
          }
        } else {
          _showError('Invalid password');
        }
      } else {
        _showError('Teacher ID not found in database');
      }
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  // Registration OTP Logic
  void _showRegistrationOtpDialog(BuildContext context) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Faculty Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Access Code to Register'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
                hintText: 'Access Code'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = otpController.text.trim();
              
              if (code == '8488') {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.teacherRegister);
              } else if (code == 'admin') { // Hidden admin access just in case
                 final prefs = await SharedPreferences.getInstance();
                 await prefs.setString('auth_role', 'admin');
                 if (context.mounted) {
                   Navigator.pop(ctx);
                   Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
                 }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Access Code')));
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Portal Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.admin_panel_settings, size: 64, color: theme.primaryColor),
                  const SizedBox(height: 24),
                  Text(
                    'Faculty Access',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // Teacher ID Dropdown
                  _isFetchingTeachers 
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: _selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Select Teacher ID',
                          prefixIcon: Icon(Icons.badge),
                          border: OutlineInputBorder(),
                        ),
                        items: _teacherIds.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
                        onChanged: (v) => setState(() => _selectedTeacherId = v),
                        validator: (v) => v == null ? 'Required' : null,
                        hint: const Text('Choose your ID'),
                      ),

                  const SizedBox(height: 16),
                  
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
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Login'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Create Account Link
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => _showRegistrationOtpDialog(context),
                      icon: Icon(Icons.person_add, size: 16, color: Colors.grey.shade600),
                      label: Text(
                        'Create Teacher Account', 
                        style: TextStyle(color: Colors.grey.shade600)
                      ),
                    ),
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

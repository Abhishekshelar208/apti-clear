import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  // Add Teacher functionality moved to Self-Registration
  // Controllers removed

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: theme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Welcome, Admin',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Teacher Management is now handled via Self-Registration.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            
            Card(
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.manageFaculty),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.manage_accounts, size: 48, color: theme.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Manage Faculty',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Assign Class Permissions'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text('Monitor Analytics (Coming Soon)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

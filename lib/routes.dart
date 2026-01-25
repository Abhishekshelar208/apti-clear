import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/weekly_topic_screen.dart';
import 'screens/friday_test_ready_screen.dart';
import 'screens/test_interface_screen.dart';
import 'screens/result_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/practice_test_screen.dart';
import 'screens/teacher_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/teacher_live_monitoring_screen.dart';
import 'screens/auth_check_screen.dart';
import 'screens/teacher_registration_screen.dart';
import 'screens/admin_manage_faculty_screen.dart';

class AppRoutes {
  static const login = '/';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const teacherDashboard = '/teacher-dashboard';
  static const weeklyTopic = '/weekly-topic';
  static const testReady = '/test-ready';
  static const testInterface = '/test';
  static const result = '/result';
  static const progress = '/progress';
  static const practiceTest = '/practice-test';
  static const teacherLogin = '/teacher-login';
  static const adminDashboard = '/admin-dashboard';
  static const liveMonitor = '/live-monitor';
  static const authCheck = '/auth-check';
  static const teacherRegister = '/teacher-register';
  static const manageFaculty = '/manage-faculty';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const StudentDashboard(),
    teacherDashboard: (context) => const TeacherDashboard(),
    weeklyTopic: (context) => const WeeklyTopicScreen(),
    testReady: (context) => const FridayTestReadyScreen(),
    testInterface: (context) => const TestInterfaceScreen(),
    result: (context) => const ResultScreen(),
    progress: (context) => const ProgressScreen(),
    practiceTest: (context) => const PracticeTestScreen(),
    teacherLogin: (context) => const TeacherLoginScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
    liveMonitor: (context) => const TeacherLiveMonitoringScreen(),
    authCheck: (context) => const AuthCheckScreen(),
    teacherRegister: (context) => const TeacherRegistrationScreen(),
    manageFaculty: (context) => const AdminManageFacultyScreen(),
  };
}

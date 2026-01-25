import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _database = FirebaseDatabase.instance.ref();
  
  // Student Profile
  String? _studentId;
  String? _studentName;
  String _year = 'FE';
  String _branch = 'CO';
  String _division = 'A';
  bool _isLoading = true;

  // Live Data (Default/Loading State)
  String _currentTopic = "Loading...";
  String _topicStatus = "Not Started";
  String _testDay = "Friday";
  String _weeklyTip = "Stay consistent!";
  
  // Listener Subscriptions
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_studentId == null) {
      _initializeDashboard();
    }
  }

  Future<void> _initializeDashboard() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    
    // 1. Try getting ID from Arguments
    if (args is String) {
      _studentId = args;
    } 
    
    // 2. Fallback: Try getting ID from SharedPreferences
    if (_studentId == null) {
      final prefs = await SharedPreferences.getInstance();
      _studentId = prefs.getString('auth_id');
      // Optimistic load of name
      if (mounted) {
        setState(() {
          _studentName = prefs.getString('auth_name'); 
        });
      }
    }

    // 3. Fetch Data
    if (_studentId != null) {
      await _fetchStudentProfile();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudentProfile() async {
    if (_studentId == null) return;
    try {
      final snapshot = await _database.child('students').child(_studentId!).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Cache the name for future
        final name = data['fullName'];
        final prefs = await SharedPreferences.getInstance();
        if (name != null) {
            await prefs.setString('auth_name', name);
        }

        if (mounted) {
          setState(() {
            _studentName = name;
            _year = data['year'] ?? 'FE';
            _branch = data['branch'] ?? 'CO';
            _division = data['division'] ?? 'A';
          });
          _listenToDashboardData();
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToDashboardData() {
    // Current Path: topic_data/{year}/{branch}/{division}
    final cohortRef = _database.child('topic_data').child(_year).child(_branch).child(_division);

    // 1. Weekly Topic Listener
    cohortRef.child('weekly_topic').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _currentTopic = data['name'] ?? "No Topic";
          _topicStatus = data['status'] ?? "Not Started";
          _testDay = data['testDay'] ?? "Friday";
        });
      }
    });

    // 2. Tip Listener
    cohortRef.child('tip').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _weeklyTip = data['content'] ?? "Stay consistent!";
        });
      }
    });
  }

  // ============ DUMMY STATS ============
  static const int daysUntilTest = 2; 
  static const int testsGiven = 6;
  static const String averageScore = "62%";
  static const String lastWeekScore = "58%";

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 1400 ? 1200.0 : screenWidth * 0.9;

    return Scaffold(
      body: Column(
        children: [
          // ============ TOP BAR ============
          _buildTopBar(context),

          // ============ MAIN CONTENT ============
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: contentWidth,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      Text(
                        'Your Cohort: $_year $_branch $_division', 
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 8),

                      // ============ MAIN FOCUS CARD ============
                      _buildWeeklyTopicCard(context),

                      const SizedBox(height: 32),

                      // ============ QUICK STATS ============
                      _buildQuickStats(context, screenWidth),

                      const SizedBox(height: 32),
                      
                      // ============ FRIDAY TEST ENTRY ============
                      _buildFridayTestEntryCard(context),

                      const SizedBox(height: 32),

                      // ============ TIP ============
                      _buildMotivationalTip(context),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DMCE AptiLab',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.logout),
                color: theme.primaryColor,
                tooltip: 'Logout',
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
              const SizedBox(width: 8),
              Icon(Icons.account_circle, color: theme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Welcome,', style: theme.textTheme.bodySmall),
                  Text(
                    _studentName ?? "Student",
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTopicCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color statusColor;
    IconData statusIcon;

    switch (_topicStatus) {
      case "Completed":
        statusColor = colorScheme.secondary; 
        statusIcon = Icons.check_circle;
        break;
      case "In Progress":
        statusColor = Colors.orange;
        statusIcon = Icons.timelapse;
        break;
      default: 
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  "This Week's Aptitude Topic",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Topic Name:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(width: 12),
                Text(_currentTopic, style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Status:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(width: 12),
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(_topicStatus, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: statusColor)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Test Day:', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                const SizedBox(width: 12),
                Text(_testDay, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: theme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Test Countdown: $daysUntilTest Days Left',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // PASS STUDENT ID HERE
                  Navigator.pushNamed(
                    context,
                    AppRoutes.weeklyTopic,
                    arguments: _studentId, 
                  );
                },
                child: const Text('View Topic & Resources'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, double screenWidth) {
    final theme = Theme.of(context);
    final isMobile = screenWidth < 768;
    
    final card1 = _buildStatCard(context, 'Tests Given', testsGiven.toString(), Icons.assignment);
    final card2 = _buildStatCard(context, 'Average Score', averageScore, Icons.trending_up);
    final card3 = _buildStatCard(context, 'Last Week', lastWeekScore, Icons.history);

    if (isMobile) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: theme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text('My Progress Snapshot', style: theme.textTheme.titleLarge?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          card1, const SizedBox(height: 16), card2, const SizedBox(height: 16), card3, 
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.progress), child: const Text("View Full History")))
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text('My Progress Snapshot', style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.progress),
              style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              child: const Text('View Full History'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: theme.primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.displaySmall?.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalTip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: theme.primaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip of the Week', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                const SizedBox(height: 6),
                Text(_weeklyTip, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFridayTestEntryCard(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.testReady,
            arguments: _studentId,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.assignment_late, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Friday Weekly Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 4),
                    Text('Click to check availability', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
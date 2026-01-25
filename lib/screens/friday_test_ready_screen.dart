import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../routes.dart';

class FridayTestReadyScreen extends StatefulWidget {
  const FridayTestReadyScreen({super.key});

  @override
  State<FridayTestReadyScreen> createState() => _FridayTestReadyScreenState();
}

class _FridayTestReadyScreenState extends State<FridayTestReadyScreen> {
  final _database = FirebaseDatabase.instance.ref();
  
  String? _studentId;
  bool _isLoading = true;
  bool _isTestEnabled = false;
  List<Map<String, dynamic>> _questions = [];
  String _topicName = "Loading...";
  String _duration = "30 mins";
  bool _hasAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_studentId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _studentId = args;
        _fetchTestData();
      } else {
        // Fallback or Error
        setState(() { 
          _isLoading = false; 
          _topicName = "Error: Student ID Missing";
        });
      }
    }
  }

  Future<void> _fetchTestData() async {
    if (_studentId == null) return;
    try {
      // 1. Get Cohort
      final profileSnapshot = await _database.child('students').child(_studentId!).get();
      if (!profileSnapshot.exists) return;
      
      final profile = profileSnapshot.value as Map<dynamic, dynamic>;
      final year = profile['year'] ?? 'FE';
      final branch = profile['branch'] ?? 'CO';
      final division = profile['division'] ?? 'A';

      // 2. Check for existing attempts
      // We assume attempts are tracked by date or just a flat check for the current active test.
      // For simplicity based on requirements: Check if ANY attempt exists for now, 
      // or check a specific "lastAttemptDate". 
      // Requirement: "Student never able to give that test again". 
      // Let's check `friday_test_attempts` node.
      final attemptSnapshot = await _database.child('students').child(_studentId!).child('friday_test_attempts').get();
      if (attemptSnapshot.exists) {
        _hasAttempted = true;
      }

      // 3. Fetch Friday Test Data
      final dataSnapshot = await _database.child('topic_data').child(year).child(branch).child(division).get();
      
      if (dataSnapshot.exists) {
        final data = dataSnapshot.value as Map<dynamic, dynamic>;
        
        // Topic Name
        final topicData = data['weekly_topic'] as Map?;
        _topicName = topicData?['name'] ?? "Weekly Test";

        // Friday Test
        final testData = data['friday_test'] as Map?;
        if (testData != null) {
           _isTestEnabled = testData['isEnabled'] ?? false;
           _duration = "${testData['duration'] ?? 30} Minutes";
           
           final qList = testData['questions'];
           if (qList is List) {
             _questions = [];
             for (var q in qList) {
               if (q != null) _questions.add(Map<String, dynamic>.from(q));
             }
           }
        }
      }

    } catch (e) {
      debugPrint("Error fetching test data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTest() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No questions available for this test.')));
      return;
    }

    // Shuffle questions for randomization
    final shuffledQuestions = List<Map<String, dynamic>>.from(_questions)..shuffle();

    Navigator.pushReplacementNamed(
      context, 
      AppRoutes.testInterface,
      arguments: {
        'title': _topicName,
        'duration': int.tryParse(_duration.split(' ')[0]) ?? 30, // Extract minutes
        'questions': shuffledQuestions,
        'studentId': _studentId, // Pass ID for live tracking
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final isLocked = !_isTestEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Friday Test'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Topic: $_topicName', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Duration: $_duration', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.help_outline, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Questions: ${_questions.length}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Status Card
                  Card(
                  color: _hasAttempted 
                    ? Colors.orange.shade50
                    : isLocked ? Colors.grey.shade100 : Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _hasAttempted ? Icons.check_circle : (isLocked ? Icons.lock : Icons.lock_open), 
                          size: 48, 
                          color: _hasAttempted ? Colors.orange : (isLocked ? Colors.grey : Colors.green)
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasAttempted ? 'TEST COMPLETED' : (isLocked ? 'TEST LOCKED' : 'TEST AVAILABLE'),
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: _hasAttempted 
                                ? Colors.orange.shade800
                                : (isLocked ? Colors.grey : Colors.green.shade700)
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _hasAttempted 
                              ? 'You have already submitted this test.'
                              : (isLocked ? 'Please wait for your teacher to enable the test.' : 'Good luck!'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Start Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (isLocked || _hasAttempted) ? null : _startTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('START TEST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
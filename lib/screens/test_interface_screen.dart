import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../routes.dart';

class TestInterfaceScreen extends StatefulWidget {
  const TestInterfaceScreen({super.key});

  @override
  State<TestInterfaceScreen> createState() => _TestInterfaceScreenState();
}

class _TestInterfaceScreenState extends State<TestInterfaceScreen> with WidgetsBindingObserver {
  final _database = FirebaseDatabase.instance.ref();
  // Exam Data
  // Exam Data
  List<Map<String, dynamic>> _questions = [];
  bool _isLoaded = false;
  String _examTitle = 'Practice Test';
  String? _studentId;
  String _studentName = "Student";

  // Anti-Cheat & Live Tracking
  DateTime? _lastBackgroundTime;
  int _violationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // State
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Question Index -> Option Index
  Timer? _timer;
  int _timeRemainingSeconds = 1800; // Default 30 mins
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List) {
        // Passed list of questions
        _questions = args.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoaded = true;
        _startTimer();
      } else if (args is Map) {
         // Passed object with config
         _questions = List<Map<String, dynamic>>.from(args['questions'] ?? []);
         _examTitle = args['title'] ?? 'Practice Test';
         _examTitle = args['title'] ?? 'Practice Test';
         _timeRemainingSeconds = (args['duration'] ?? 30) * 60;
         _studentId = args['studentId'];
         _isLoaded = true;
         _startTimer();
         if (_studentId != null) _fetchCohortAndInitLive();
      } else {
        // Fallback for direct navigation (Dev mode)
        _loadDummyData();
      }
    }

    }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_studentId == null) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // User left the app
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // User returned
      if (_lastBackgroundTime != null) {
        final durationAway = DateTime.now().difference(_lastBackgroundTime!).inSeconds;
        if (durationAway > 3) { // Buffer for accidental swipes
           _violationCount++;
           _reportViolation(durationAway);
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('WARNING: You left the test window for ${durationAway}s! This has been recorded.'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 5),
             )
           );
        }
        _lastBackgroundTime = null;
      }
    }
  }

  Future<void> _reportViolation(int secondsAway) async {
    // We need cohort details to construct path. 
    // Since we didn't pass full profile, we might need to fetch or infer.
    // Ideally, pass cohort args. 
    // For now, assume we can find the node via `friday_test_live` index or structural args.
    // IMPROVEMENT: Pass Year/Branch/Div in args to avoid re-fetch.
    
    // For this implementation, I will rely on finding the student in live node 
    // OR create a flattened structure for simpler writes if allowed.
    // However, adhering to user's "Teacher sees live update", I probably need the path.
    // Let's UPDATE dependency args to include cohort info or just use Student ID index if possible.
    // Actually, `friday_test_live` was planned as `{year}/{branch}/{div}/{id}`.
    // I need those values. I will modify `didChangeDependencies` to parse them if available,
    // or just fetch them once on init.
    
    if (_cohortPath != null) {
       final violationData = {
         'timestamp': DateTime.now().toIso8601String(),
         'durationAway': secondsAway,
         'message': 'Left app/tab for ${secondsAway}s'
       };
       
       await _database.child(_cohortPath!).child(_studentId!).child('violations').push().set(violationData);
       await _database.child(_cohortPath!).child(_studentId!).update({
         'status': 'VIOLATION_DETECTED',
         'lastActive': DateTime.now().toIso8601String(),
         'violationCount': _violationCount,
         'lastViolationMessage': 'Left for ${secondsAway}s'
       });
    }
  }
  
  String? _cohortPath; // "friday_test_live/FE/CO/A"
  
  Future<void> _fetchCohortAndInitLive() async {
     if (_studentId == null) return;
     final sSnap = await _database.child('students').child(_studentId!).get();
     if (sSnap.exists) {
       final data = sSnap.value as Map;
       final year = data['year'] ?? 'FE';
       final branch = data['branch'] ?? 'CO';
       final div = data['division'] ?? 'A';
       

       final name = data['name'] ?? 'Student';
       
       setState(() {
         _cohortPath = 'friday_test_live/$year/$branch/$div';
         _studentName = name;
       });

       _updateLiveStatus('ACTIVE');
     }
  }

  void _updateLiveStatus(String status) {
    if (_cohortPath == null || _studentId == null) return;
    
    _database.child(_cohortPath!).child(_studentId!).update({
      'name': _studentName,
      'status': status,
      'score': _calculateCurrentScore(),
      'solved': _selectedAnswers.length,
      'lastActive': DateTime.now().toIso8601String(),
    });
  }

  int _calculateCurrentScore() {
    int score = 0;
    _selectedAnswers.forEach((qIndex, aIndex) {
       if (qIndex < _questions.length) {
         final correct = _questions[qIndex]['correctAnswer'];
         int realCorrect = 0;
         if (correct is int) {
           realCorrect = correct;
         } else if (correct is String) {
           realCorrect = int.parse(correct);
         }
         
         if (aIndex == realCorrect) {
           score++;
         }
       }
    });
    return score;
  }

  void _loadDummyData() {
    _questions = [
      {
        'question': 'A can do a work in 10 days, B in 15 days. Together?',
        'options': ['5 days', '6 days', '8 days', '9 days'],
        'correctAnswer': 1
      },
      {
        'question': 'Ratio of A:B is 3:5, sum is 80. Find A?',
        'options': ['20', '30', '40', '50'],
        'correctAnswer': 1
      }
    ];
    _isLoaded = true;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSeconds > 0) {
        setState(() {
          _timeRemainingSeconds--;
        });
      } else {
        _submitTest(autoSubmit: true);
      }
    });
  }



  String get _formattedTime {
    final minutes = (_timeRemainingSeconds / 60).floor();
    final seconds = _timeRemainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _submitTest({bool autoSubmit = false}) {
    _timer?.cancel();
    
    // Calculate Score
    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (int i = 0; i < _questions.length; i++) {
       if (!_selectedAnswers.containsKey(i)) {
         skipped++;
         continue;
       }
       
       final selected = _selectedAnswers[i];
       final correctIndex = _questions[i]['correctAnswer'];
       
       // Handle dynamic type safety for corrective index
       int realCorrect = 0;
       if (correctIndex is int) {
         realCorrect = correctIndex;
       } else if (correctIndex is String) {
         realCorrect = int.tryParse(correctIndex) ?? 0;
       }

       if (selected == realCorrect) {
         correct++;
       } else {
         wrong++;
       }
    }

    final resultData = {
      'totalQuestions': _questions.length,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'score': correct, // Simple scoring 1 mark per question
      'examTitle': _examTitle,
      'isAutoSubmitted': autoSubmit
    };

    // 1. Mark as Attempted (Permanent)
    if (_studentId != null) {
      // Use push() or set a flag. 
      // Requirement: "Student never able to give that test again"
      // We set a flag 'completed' = true and timestamp.
      _database.child('students').child(_studentId!).child('friday_test_attempts').set({
        'completed': true,
        'submittedAt': DateTime.now().toIso8601String(),
        'score': correct
      });
      
      // 2. Update Live Status
      _updateLiveStatus('SUBMITTED');
    }

    // Navigate to Result Screen (Replace stack so user can't go back to test)
    Navigator.pushReplacementNamed(context, AppRoutes.result, arguments: resultData);
  }

  void _showSubmitDialog() {
    final attempted = _selectedAnswers.length;
    final total = _questions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text('You have attempted $attempted out of $total questions.\nAre you sure you want to finish?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Column(
        children: [
          // Top Bar
          _buildTopBar(theme),

          // Content
          Expanded(
            child: isDesktop 
              ? Row(
                  children: [
                    Expanded(flex: 3, child: _buildQuestionArea(theme)),
                    Container(width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    SizedBox(width: 300, child: _buildOverviewPanel(theme)),
                  ],
                )
              : _buildQuestionArea(theme), // Mobile: Just question, add drawer for map later if needed
          ),
        ],
      ),
      // Floating Action Button for Mobile Map? Maybe later. 
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: _timeRemainingSeconds < 300 ? Colors.red : theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Time Left: $_formattedTime',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _timeRemainingSeconds < 300 ? Colors.red : theme.primaryColor,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(
            'Q: ${_currentQuestionIndex + 1}/${_questions.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(ThemeData theme) {
    if (_questions.isEmpty) return const Center(child: Text('No Questions Found'));

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Text
                Text(
                  'Question ${_currentQuestionIndex + 1}',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  question['question'] ?? '',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 32),

                // Options
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedAnswers[_currentQuestionIndex] = index);
                        _updateLiveStatus('ACTIVE');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? theme.primaryColor.withValues(alpha: 0.05) : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey),
                                color: isSelected ? theme.primaryColor : null,
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Text(options[index], style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        // Navigation Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentQuestionIndex > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _currentQuestionIndex--),
                  child: const Text('Previous'),
                )
              else
                const SizedBox(width: 1), // Spacer

              if (_currentQuestionIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed: () => setState(() => _currentQuestionIndex++),
                  child: const Text('Save & Next'),
                )
              else
                ElevatedButton(
                  onPressed: _showSubmitDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Submit Test'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewPanel(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Questions Overview', style: theme.textTheme.titleMedium),
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final isAttempted = _selectedAnswers.containsKey(index);
              final isCurrent = index == _currentQuestionIndex;

              return InkWell(
                onTap: () => setState(() => _currentQuestionIndex = index),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrent ? theme.primaryColor : (isAttempted ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1)),
                    border: Border.all(
                      color: isCurrent ? theme.primaryColor : (isAttempted ? Colors.green : Colors.grey.withValues(alpha: 0.3))
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : (isAttempted ? Colors.green[800] : Colors.black87),
                        fontWeight: isCurrent || isAttempted ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildLegend(),
      ],
    );
  }
  
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
             Container(width: 12, height: 12, color: Colors.green.withValues(alpha: 0.2)), 
             const SizedBox(width: 8), const Text('Attempted')
          ]),
          const SizedBox(height: 4),
          Row(children: [
             Container(width: 12, height: 12, color: Colors.grey.withValues(alpha: 0.1)), 
             const SizedBox(width: 8), const Text('Not Visited')
          ]),
        ],
      ),
    );
  }
}
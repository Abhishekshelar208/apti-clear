import 'package:flutter/material.dart';

class PracticeTestScreen extends StatefulWidget {
  const PracticeTestScreen({super.key});

  @override
  State<PracticeTestScreen> createState() => _PracticeTestScreenState();
}

class _PracticeTestScreenState extends State<PracticeTestScreen> {
  // Questions passed from WeeklyTopicScreen
  List<Map<String, dynamic>> _questions = [];
  bool _isLoaded = false;
  
  // Test State
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // Map<QuestionIndex, OptionIndex>
  bool _isSubmitted = false;
  int _score = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is List) {
        // Safe conversion of arguments to List<Map>
        _questions = args.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      _isLoaded = true;
    }
  }

  void _selectOption(int optionIndex) {
    if (_isSubmitted) return; // Prevent changing after submit
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    }
  }

  void _submitTest() {
    // Calculate Score
    int correctCount = 0;
    for (int i = 0; i < _questions.length; i++) {
      final correctAnswerIndex = _questions[i]['correctAnswer']; // 0-indexed assumed
      if (_selectedAnswers[i] == correctAnswerIndex) {
        correctCount++;
      }
    }

    setState(() {
      _score = correctCount;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Practice Test")),
        body: const Center(child: Text("No questions in this practice set.")),
      );
    }

    if (_isSubmitted) {
      return _buildResultScreen(theme);
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    // Ensure options is a list
    final List<dynamic> rawOptions = currentQuestion['options'] ?? [];
    final List<String> options = rawOptions.map((e) => e.toString()).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${_currentQuestionIndex + 1}/${_questions.length}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              color: theme.primaryColor,
            ),
            const SizedBox(height: 32),

            // Question Text
            Text(
              currentQuestion['question'] ?? "Question Text Missing",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (c, i) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                  return InkWell(
                    onTap: () => _selectOption(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.white,
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.primaryColor : Colors.grey.shade400,
                              ),
                              color: isSelected ? theme.primaryColor : Colors.transparent,
                            ),
                            child: isSelected 
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              options[index],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  OutlinedButton(
                    onPressed: _prevQuestion,
                    child: const Text("Previous"),
                  )
                else
                  const SizedBox.shrink(), // Spacer

                if (_currentQuestionIndex < _questions.length - 1)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text("Next"),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _submitTest,
                    child: const Text("Submit Test", style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(ThemeData theme) {
    final percentage = (_score / _questions.length) * 100;
    Color resultColor = percentage >= 70 ? Colors.green : (percentage >= 40 ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(title: const Text("Test Results")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                percentage >= 70 ? Icons.emoji_events : Icons.assignment_late,
                size: 80,
                color: resultColor,
              ),
              const SizedBox(height: 24),
              Text(
                "You Scored",
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                "$_score / ${_questions.length}",
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text("Back to Topic"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Exit Test?"),
        content: const Text("Your progress will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(c); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text("Exit", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

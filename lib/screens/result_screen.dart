// ========== PART B: TEST RESULT SCREEN ==========
import 'package:flutter/material.dart';

import '../routes.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Extract Args
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // 2. Default/Fallback Data
    final totalQuestions = args?['totalQuestions'] ?? 0;
    final correctAnswers = args?['correct'] ?? 0;
    // Calculate percentage safely
    final percentage = totalQuestions > 0 
        ? ((correctAnswers / totalQuestions) * 100).round() 
        : 0;
    
    final topicName = args?['examTitle'] ?? 'Test Result';
    
    // Determine Feedback
    String strengthLevel = 'NEEDS IMPROVEMENT';
    String feedbackMessage = 'Keep practicing to improve your score.';
    
    if (percentage >= 80) {
      strengthLevel = 'EXCELLENT';
      feedbackMessage = 'Outstanding performance! You have a strong grasp of this topic.';
    } else if (percentage >= 60) {
      strengthLevel = 'GOOD';
      feedbackMessage = 'You are doing well, but there is still room for improvement.';
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      // Background handled by AppTheme
      body: Column(
        children: [
          // SECTION 1: HEADER
          _buildHeader(context),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // SECTION 2: SCORE SUMMARY CARD
                      _buildScoreSummaryCard(context, isDesktop, correctAnswers, totalQuestions, percentage),

                      const SizedBox(height: 24),

                      // SECTION 3: PERFORMANCE FEEDBACK
                      _buildPerformanceFeedbackCard(context, isDesktop, topicName, strengthLevel, feedbackMessage),

                      const SizedBox(height: 24),

                      // SECTION 4: NEXT ACTIONS
                      _buildNextActionsCard(context, isDesktop),
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

  // ========== SECTION 1: HEADER ==========
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DMCE AptiLab',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
          Text(
            'Test Result',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION 2: SCORE SUMMARY CARD ==========
  Widget _buildScoreSummaryCard(BuildContext context, bool isDesktop, int correct, int total, int pct) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assessment_outlined,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Test Result Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Score Details
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _buildScoreItem(context, 'Score', '$correct / $total')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildScoreItem(context, 'Percentage', '$pct%')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildScoreItem(context, 'Accuracy', '$pct%')),
                ],
              )
            else
              Column(
                children: [
                  _buildScoreItem(context, 'Score', '$correct / $total'),
                  const SizedBox(height: 20),
                  _buildScoreItem(context, 'Percentage', '$pct%'),
                  const SizedBox(height: 20),
                  _buildScoreItem(context, 'Accuracy', '$pct%'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION 3: PERFORMANCE FEEDBACK CARD ==========
  Widget _buildPerformanceFeedbackCard(BuildContext context, bool isDesktop, String topic, String strength, String msg) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Performance Feedback',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Topic
            _buildInfoRow(context, 'Topic', topic),

            const SizedBox(height: 16),

            // Strength Level
            _buildInfoRow(context, 'Strength Level', strength),

            const SizedBox(height: 24),

            // Divider
            Divider(color: Colors.grey.withValues(alpha: 0.3)),

            const SizedBox(height: 24),

            // Feedback Message
            Text(
              'Feedback Message',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
              ),
              child: Text(
                msg,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ========== SECTION 4: NEXT ACTIONS CARD ==========
  Widget _buildNextActionsCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 40 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigate_next,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Next Steps',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'View Progress History',
                      Icons.history,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'Back to Dashboard',
                      Icons.dashboard_outlined,
                      isPrimary: true,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildActionButton(
                    context,
                    'View Progress History',
                    Icons.history,
                    isPrimary: false,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    context,
                    'Back to Dashboard',
                    Icons.dashboard_outlined,
                    isPrimary: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String label,
      IconData icon, {
        required bool isPrimary,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isPrimary
          ? ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.dashboard, (route) => false);
        },
        icon: Icon(icon, size: 20),
        label: Text(label),
        // Style handled largely by AppTheme, but ensuring specific button structure
      )
          : OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.progress);
        },
        icon: Icon(icon, size: 20),
        label: Text(label),
        // Style handled largely by AppTheme
      ),
    );
  }
}
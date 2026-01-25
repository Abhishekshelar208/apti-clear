import 'package:flutter/material.dart';
import '../routes.dart';

// ========== DUMMY DATA MODELS ==========
class TestRecord {
  final int week;
  final String topic;
  final int score;
  final String status;

  TestRecord({
    required this.week,
    required this.topic,
    required this.score,
    required this.status,
  });
}

// ========== DUMMY DATA ==========
final List<TestRecord> dummyTestHistory = [
  TestRecord(week: 1, topic: 'Percentages', score: 52, status: 'Needs Practice'),
  TestRecord(week: 2, topic: 'Ratio & Proportion', score: 60, status: 'Improving'),
  TestRecord(week: 3, topic: 'Profit & Loss', score: 58, status: 'Average'),
  TestRecord(week: 4, topic: 'Time & Work', score: 70, status: 'Good'),
  TestRecord(week: 5, topic: 'Speed & Distance', score: 65, status: 'Good'),
  TestRecord(week: 6, topic: 'Simple Interest', score: 78, status: 'Excellent'),
];

const int totalTests = 6;
const int averageScore = 64;
const int bestScore = 78;

// ========== MAIN PROGRESS SCREEN ==========
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    
    // Background color handled by AppTheme scaffoldBackgroundColor

    return Scaffold(
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
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 2: OVERALL SUMMARY CARDS
                      _buildOverallSummaryCards(context, isDesktop),

                      const SizedBox(height: 32),

                      // SECTION 3: PROGRESS TABLE
                      _buildProgressTable(context, isDesktop),

                      const SizedBox(height: 32),

                      // SECTION 4: IMPROVEMENT VISUAL
                      _buildImprovementVisual(context, isDesktop),

                      const SizedBox(height: 32),

                      // SECTION 5: MOTIVATIONAL MESSAGE
                      _buildMotivationalMessage(context, isDesktop),

                      const SizedBox(height: 32),

                      // SECTION 6: ACTION BUTTONS
                      _buildActionButton(context),
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
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
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
            'My Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION 2: OVERALL SUMMARY CARDS ==========
  Widget _buildOverallSummaryCards(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
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
                  'Overall Performance Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Summary Cards
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(context, 'Total Tests', '$totalTests', Icons.quiz_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(context, 'Average Score', '$averageScore%', Icons.trending_up)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard(context, 'Best Score', '$bestScore%', Icons.star_outline)),
                ],
              )
            else
              Column(
                children: [
                  _buildSummaryCard(context, 'Total Tests', '$totalTests', Icons.quiz_outlined),
                  const SizedBox(height: 16),
                  _buildSummaryCard(context, 'Average Score', '$averageScore%', Icons.trending_up),
                  const SizedBox(height: 16),
                  _buildSummaryCard(context, 'Best Score', '$bestScore%', Icons.star_outline),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.primaryColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.primaryColor, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
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

  // ========== SECTION 3: PROGRESS TABLE ==========
  Widget _buildProgressTable(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Test History',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Table
            isDesktop ? _buildDesktopTable(context) : _buildMobileTable(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final theme = Theme.of(context);
    
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header Row
        TableRow(
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.05),
          ),
          children: [
            _buildTableHeader(context, 'Week'),
            _buildTableHeader(context, 'Topic'),
            _buildTableHeader(context, 'Score'),
            _buildTableHeader(context, 'Status'),
          ],
        ),

        // Data Rows
        ...dummyTestHistory.map((record) => TableRow(
          children: [
            _buildTableCell(context, 'Week ${record.week}'),
            _buildTableCell(context, record.topic),
            _buildTableCell(context, '${record.score}%', isBold: true),
            _buildTableCell(context, record.status, isStatus: true),
          ],
        )),
      ],
    );
  }

  Widget _buildMobileTable(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: dummyTestHistory.map((record) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week ${record.week}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  '${record.score}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.topic,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              record.status,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTableHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(BuildContext context, String text, {bool isBold = false, bool isStatus = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: isStatus ? theme.colorScheme.onSurface.withOpacity(0.7) : theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ========== SECTION 4: IMPROVEMENT VISUAL ==========
  Widget _buildImprovementVisual(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.show_chart,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Improvement Trend',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Simple Bar Chart using Containers
            _buildSimpleBarChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBarChart(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Bar Chart
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dummyTestHistory.map((record) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Score Label
                      Text(
                        '${record.score}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bar
                      Container(
                        width: double.infinity,
                        height: (record.score / 100) * 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.primaryColor,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Week Labels
        Row(
          children: dummyTestHistory.map((record) {
            return Expanded(
              child: Text(
                'W${record.week}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ========== SECTION 5: MOTIVATIONAL MESSAGE ==========
  Widget _buildMotivationalMessage(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: theme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insight',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your scores are improving steadily. Consistency is more important than perfection. Keep practicing!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SECTION 6: ACTION BUTTON ==========
  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.dashboard, (route) => false);
        },
        icon: const Icon(Icons.dashboard_outlined, size: 20),
        label: const Text('Back to Dashboard'),
        // theme handles style
      ),
    );
  }
}
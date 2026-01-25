import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../routes.dart';

class WeeklyTopicScreen extends StatefulWidget {
  const WeeklyTopicScreen({super.key});

  @override
  State<WeeklyTopicScreen> createState() => _WeeklyTopicScreenState();
}

class _WeeklyTopicScreenState extends State<WeeklyTopicScreen> {
  final _database = FirebaseDatabase.instance.ref();
  
  // Data State
  String _topicName = "Loading...";
  String _topicDescription = "Please wait, fetching topic details...";
  String _testDay = "Pending";
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;

  String? _studentId; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _studentId = args;
      _fetchData();
    } else {
      _fetchDataForDev();
    }
  }

  Future<void> _fetchDataForDev() async {
     if (mounted) {
       setState(() {
         _topicName = "No Student ID";
         _topicDescription = "Please navigate from the Dashboard.";
         _isLoading = false;
       });
     }
  }

  Future<void> _fetchData() async {
    if (_studentId == null) return;
    try {
      // 1. Get Profile to know Cohort
      final profileSnapshot = await _database.child('students').child(_studentId!).get();
      if (!profileSnapshot.exists) return; 
      
      final profile = profileSnapshot.value as Map<dynamic, dynamic>;
      final year = profile['year'] ?? 'FE';
      final branch = profile['branch'] ?? 'CO';
      final division = profile['division'] ?? 'A';

      // 2. Get Topic Data
      final topicRef = _database.child('topic_data').child(year).child(branch).child(division);
      
      // Fetch Weekly Topic
      final topicSnapshot = await topicRef.child('weekly_topic').get();
      if (topicSnapshot.exists) {
        final data = topicSnapshot.value as Map<dynamic, dynamic>;
        _topicName = data['name'] ?? "No Topic";
        _topicDescription = data['description'] ?? "No description available.";
        _testDay = data['testDay'] ?? "Pending";
      } else {
         _topicName = "No Topic Assigned";
         _topicDescription = "Your teacher hasn't posted a topic yet.";
      }

      // Fetch Resources
      final resSnapshot = await topicRef.child('resources').get();
      List<Map<String, dynamic>> loadedResources = [];
      if (resSnapshot.exists) {
        final resData = resSnapshot.value;
        if (resData is List) {
           for (var item in resData) {
             if (item != null) loadedResources.add(Map<String, dynamic>.from(item));
           }
        } else if (resData is Map) {
          resData.forEach((key, value) {
            loadedResources.add(Map<String, dynamic>.from(value));
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _resources = loadedResources;
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint("Error loading topic: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Checklist items (local state - temporary per session)
  final List<Map<String, dynamic>> checklistItems = [
    {'text': 'Watched concept video', 'checked': false},
    {'text': 'Understood solved examples', 'checked': false},
    {'text': 'Practiced questions', 'checked': false},
  ];

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication); // Open in external browser/tab
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch URL: $urlString')),
          );
        }
      }
    }
  }

  void _openPracticeTest(List<dynamic> questions) {
    if (questions.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This practice set has no questions!')),
       );
       return;
    }
    Navigator.pushNamed(
      context, 
      AppRoutes.practiceTest, 
      arguments: questions
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                      _buildTopicOverviewCard(),
                      const SizedBox(height: 24),
                      _buildLearningResourcesSection(context),
                      const SizedBox(height: 24),
                      _buildPreparationChecklist(),
                      const SizedBox(height: 24),
                      _buildWeekStatusCard(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Name
          Text(
            'DMCE AptiLab',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Page Title
          Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
              Icon(
                Icons.book,
                color: theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Topic',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicOverviewCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Aptitude Topic',
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

            // Topic Name
            Row(
              children: [
                Text(
                  'Topic Name:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _topicName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            Text(
              'Description:',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _topicDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningResourcesSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_books,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Learning Resources',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 16),
            
            if (_resources.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No resources uploaded yet."),
              )
            else
              ..._resources.map((resource) {
                // Map type string to Icon
                IconData icon;
                bool isPractice = false;
                switch(resource['type']) {
                  case 'pdf': icon = Icons.picture_as_pdf; break;
                  case 'practice': 
                    icon = Icons.assignment; 
                    isPractice = true;
                    break;
                  default: icon = Icons.play_circle_outline; // video
                }
                
                return _buildResourceCard(
                  context,
                  resource['title'] ?? 'Resource',
                  resource['subtitle'] ?? (isPractice ? 'Start Practice' : 'Click to open'),
                  icon,
                  () {
                    if (isPractice) {
                       _openPracticeTest(resource['questions'] ?? []);
                    } else {
                       _launchURL(resource['url'] ?? '');
                    }
                  }
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) { // Changed signature to accept generic onTap
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: theme.primaryColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationChecklist() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: theme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Preparation Checklist',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, thickness: 1),
            const SizedBox(height: 16),
            ...List.generate(
                checklistItems.length, (index) => _buildChecklistItem(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final theme = Theme.of(context);
    final isChecked = checklistItems[index]['checked'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            checklistItems[index]['checked'] = !isChecked;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isChecked
                ? theme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked ? theme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isChecked ? theme.primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isChecked
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  checklistItems[index]['text'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isChecked 
                      ? theme.primaryColor 
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
                    decoration: isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekStatusCard() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Test Status',
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
                Text(
                  'Test Day:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _testDay,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.testReady,
                  );
                },
                child: const Text('Go to Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
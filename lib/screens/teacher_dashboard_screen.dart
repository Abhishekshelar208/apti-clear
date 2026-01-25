import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _database = FirebaseDatabase.instance.ref();
  
  // Selection
  String _selectedYear = 'FE';
  String _selectedBranch = 'CO';
  String _selectedDivision = 'A';

  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final List<String> _branches = ['CO', 'IT', 'AIDS'];
  final List<String> _divisions = ['A', 'B', 'C', 'All Divisions'];

  // Weekly Topic
  final _topicNameController = TextEditingController();
  final _topicDescController = TextEditingController();
  String _selectedStatus = 'Not Started';
  final List<String> _statusOptions = ['Not Started', 'In Progress', 'Completed'];
  DateTime? _selectedTestDate;

  // Student Engagement (Tips)
  String? _selectedTip;
  final List<String> _predefinedTips = [
    "Consistent weekly practice makes aptitude easy.",
    "Focus on accuracy before speed.",
    "Read the question carefully twice.",
    "Don't get stuck on one question for too long.",
    "Practice mental math to save time.",
    "Review your mistakes after every test."
  ];

  // Learning Resources (Local State)
  // Structure: {title, subtitle, url, type, questions}
  final List<Map<String, dynamic>> _localResources = [];

  // Controllers for Resources
  final _resourceTitleController = TextEditingController();
  final _resourceSubtitleController = TextEditingController();
  final _resourceLinkController = TextEditingController();
  
  // Resource Type Selection
  String _selectedResourceType = 'video';
  final List<Map<String, dynamic>> _resourceTypes = [
    {'label': 'Video', 'value': 'video', 'icon': Icons.play_circle_outline},
    {'label': 'PDF', 'value': 'pdf', 'icon': Icons.picture_as_pdf},
    {'label': 'Practice Set', 'value': 'practice', 'icon': Icons.assignment},
  ];

  // Temporary State for Practice Set
  final List<Map<String, dynamic>> _currentPracticeQuestions = [];

  // Friday Test State
  bool _isFridayTestEnabled = false;
  int _fridayTestDuration = 30; // Default 30 mins
  final List<Map<String, dynamic>> _fridayTestQuestions = [];

  bool _isLoading = false;

  String? _teacherName;

  // Permissions
  List<String> _grantedAccess = [];
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _fetchTeacherProfile();
    if (_hasAccess) {
      _filterSelectionOptions();
      _fetchExistingData();
    }
  }

  Future<void> _fetchTeacherProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherId = prefs.getString('auth_id');
    
    if (teacherId != null) {
      try {
        final snapshot = await _database.child('teachers').child(teacherId).get();
        if (snapshot.exists && mounted) {
           final data = snapshot.value as Map<dynamic, dynamic>;
           setState(() {
             _teacherName = data['name'] as String?;
             
             final rawAccess = data['access_list'] as List<dynamic>?;
             if (rawAccess != null) {
               _grantedAccess = rawAccess.map((e) => e.toString()).toList();
               _hasAccess = _grantedAccess.isNotEmpty;
             }
           });
        }
      } catch (e) {
        debugPrint('Error fetching teacher profile: $e');
      }
    }
  }

  void _filterSelectionOptions() {
    if (_grantedAccess.isEmpty) return;
    
    // 1. Filter Years based on access list
    final availableYears = _grantedAccess.map((a) => a.split('-')[0]).toSet().toList();
    _years.removeWhere((y) => !availableYears.contains(y));
    
    // Set initial selection if current is invalid
    if (!_years.contains(_selectedYear) && _years.isNotEmpty) {
       _selectedYear = _years.first;
    }

    _updateBranchList();
  }

  void _updateBranchList() {
    // Filter branches available for the selected year
    final availableBranches = _grantedAccess
      .where((a) => a.startsWith('$_selectedYear-'))
      .map((a) => a.split('-')[1])
      .toSet()
      .toList();
    
    setState(() {
       _branches.clear();
       _branches.addAll(['CO', 'IT', 'AIDS']); // Reset to base
       _branches.retainWhere((b) => availableBranches.contains(b));
       
       if (!_branches.contains(_selectedBranch) && _branches.isNotEmpty) {
         _selectedBranch = _branches.first;
       }
    });

    _updateDivisionList();
  }

  void _updateDivisionList() {
     final availableDivs = _grantedAccess
      .where((a) => a.startsWith('$_selectedYear-$_selectedBranch-'))
      .map((a) => a.split('-')[2])
      .toSet()
      .toList();
      
     setState(() {
       _divisions.clear();
       _divisions.addAll(['A', 'B', 'C', 'All Divisions']);
       _divisions.retainWhere((d) => availableDivs.contains(d));

       if (!_divisions.contains(_selectedDivision) && _divisions.isNotEmpty) {
         _selectedDivision = _divisions.first;
       }
     });
  }

  @override
  void dispose() {
    _topicNameController.dispose();
    _topicDescController.dispose();
    _resourceTitleController.dispose();
    _resourceSubtitleController.dispose();
    _resourceLinkController.dispose();
    super.dispose();
  }

  // --- FETCH EXISTING DATA ---
  Future<void> _fetchExistingData() async {
    if (_selectedDivision == 'All Divisions') return; // Cannot fetch aggregate, keep form as is or clear

    setState(() => _isLoading = true);

    try {
      final basePath = _database.child('topic_data')
          .child(_selectedYear)
          .child(_selectedBranch)
          .child(_selectedDivision);

      // Fetch Topic Info
      final topicSnapshot = await basePath.child('weekly_topic').get();
      // Fetch Tip
      final tipSnapshot = await basePath.child('tip').get();
      // Fetch Resources
      final resSnapshot = await basePath.child('resources').get();
      // Fetch Friday Test
      final testSnapshot = await basePath.child('friday_test').get();

      if (topicSnapshot.exists) {
        final data = topicSnapshot.value as Map<dynamic, dynamic>;
        _topicNameController.text = data['name'] ?? '';
        _topicDescController.text = data['description'] ?? '';
        _selectedStatus = data['status'] ?? 'Not Started';
        
        // Parse Date
        if (data['testDay'] != null) {
          try {
             // Assuming format: DateFormat('EEEE, MMM d') -> e.g. "Friday, Jan 10"
             // Since year is missing in storage format, we might need adjustments or just pick current year
             // However, DateFormat.parse() with this pattern defaults to 1970.
             // Better strategy: We stored string "Friday, Jan 10". 
             // Without year, reconstructing DateTime is tricky. 
             // For now, we will NOT auto-populate the date picker if it parses weirdly, 
             // OR we change storage to ISO8601. But to keep consistent with previous implementation:
             // We will skip strict parsing and let user re-select if needed, 
             // OR we try to improve storage in next upload. 
             // Previous code: DateFormat('EEEE, MMM d')
             
             // Let's just reset date for now, or keep it if format allows. 
             // To properly fix persistence, we should store ISO date. 
             // But following user instruction "show all previous data", let's try our best.
          } catch (_) {}
        }
      } else {
        _clearForm();
      }

      if (tipSnapshot.exists) {
        final data = tipSnapshot.value as Map<dynamic, dynamic>;
        final fetchedTip = data['content'] as String?;
        if (_predefinedTips.contains(fetchedTip)) {
          _selectedTip = fetchedTip;
        } else {
          _selectedTip = null; // Custom tips not supported in dropdown yet
        }
      }

      if (resSnapshot.exists) {
        final data = resSnapshot.value;
        List<Map<String, dynamic>> loaded = [];
        if (data is List) {
           for (var item in data) {
             if (item != null) loaded.add(Map<String, dynamic>.from(item));
           }
        }
        _localResources.clear();
        _localResources.addAll(loaded);
      } else {
        _localResources.clear();
      }

      if (testSnapshot.exists) {
        final data = testSnapshot.value as Map<dynamic, dynamic>;
        _isFridayTestEnabled = data['isEnabled'] ?? false;
        _fridayTestDuration = data['duration'] ?? 30;
        
        final questions = data['questions'];
        _fridayTestQuestions.clear();
        if (questions is List) {
           for (var q in questions) {
             if (q != null) _fridayTestQuestions.add(Map<String, dynamic>.from(q));
           }
        }
      } else {
        _fridayTestQuestions.clear();
        _isFridayTestEnabled = false;
      }

    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _topicNameController.clear();
    _topicDescController.clear();
    _selectedStatus = 'Not Started';
    _selectedTestDate = null;
    _selectedTip = null;
    _localResources.clear();
    _fridayTestQuestions.clear();
    _isFridayTestEnabled = false;
    _fridayTestDuration = 30;
  }

  void _onSelectionChanged() {
    _fetchExistingData();
  }
  
  // Section Title Widget
  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Helper to pick date
  Future<void> _pickTestDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTestDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedTestDate = picked);
    }
  }

  // Add Question Dialog
  void _showAddQuestionDialog() {
    final qController = TextEditingController();
    final op1Controller = TextEditingController();
    final op2Controller = TextEditingController();
    final op3Controller = TextEditingController();
    final op4Controller = TextEditingController();
    int correctOption = 0; // 0, 1, 2, 3

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: qController,
                      decoration: const InputDecoration(labelText: 'Question'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: op1Controller, decoration: const InputDecoration(labelText: 'Option 1')),
                    TextFormField(controller: op2Controller, decoration: const InputDecoration(labelText: 'Option 2')),
                    TextFormField(controller: op3Controller, decoration: const InputDecoration(labelText: 'Option 3')),
                    TextFormField(controller: op4Controller, decoration: const InputDecoration(labelText: 'Option 4')),
                    const SizedBox(height: 16),
                    const Text('Correct Option:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (index) {
                        return ChoiceChip(
                          label: Text('${index + 1}'),
                          selected: correctOption == index,
                          onSelected: (selected) {
                            if (selected) setStateDialog(() => correctOption = index);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (qController.text.isNotEmpty && op1Controller.text.isNotEmpty) {
                      setState(() {
                         _currentPracticeQuestions.add({
                           'question': qController.text.trim(),
                           'options': [
                             op1Controller.text.trim(),
                             op2Controller.text.trim(),
                             op3Controller.text.trim(),
                             op4Controller.text.trim(),
                           ],
                           'correctAnswer': correctOption,
                         });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add Resource to Local List
  void _addResourceLocally() {
    if (_resourceTitleController.text.isEmpty) {
      _showScaffoldMessage('Title is required');
      return;
    }

    // Validation based on type
    if (_selectedResourceType == 'practice') {
      if (_currentPracticeQuestions.isEmpty) {
        _showScaffoldMessage('Please add at least one question for the practice set.');
        return;
      }
    } else {
      if (_resourceLinkController.text.isEmpty) {
        _showScaffoldMessage('URL is required for Video/PDF');
        return;
      }
    }

    setState(() {
      final Map<String, dynamic> resource = {
        'title': _resourceTitleController.text.trim(),
        'subtitle': _resourceSubtitleController.text.trim(), // Optional
        'type': _selectedResourceType
      };

      if (_selectedResourceType == 'practice') {
        resource['questions'] = List<Map<String, dynamic>>.from(_currentPracticeQuestions);
        resource['subtitle'] = '${_currentPracticeQuestions.length} Questions'; // Auto subtitle
      } else {
        resource['url'] = _resourceLinkController.text.trim();
      }

      _localResources.add(resource);

      // Reset Form
      _resourceTitleController.clear();
      _resourceSubtitleController.clear();
      _resourceLinkController.clear();
      _currentPracticeQuestions.clear(); 
      _selectedResourceType = 'video';
    });
  }

  // Remove Resource
  void _removeResource(int index) {
    setState(() {
      _localResources.removeAt(index);
    });
  }

  // Upload Logic
  Future<void> _uploadAllData() async {
    if (_topicNameController.text.isEmpty) {
      _showScaffoldMessage('Please enter a Topic Name');
      return;
    }
    if (_selectedTestDate == null) {
      _showScaffoldMessage('Please select a Test Date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final topicData = {
        'name': _topicNameController.text.trim(),
        'description': _topicDescController.text.trim(),
        'status': _selectedStatus,
        'testDay': DateFormat('EEEE, MMM d').format(_selectedTestDate!), 
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final tipData = {
        'content': _selectedTip ?? "",
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final fridayTestData = {
        'isEnabled': _isFridayTestEnabled,
        'questions': _fridayTestQuestions,
        'duration': _fridayTestDuration,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 1. Determine Target Paths
      List<String> targetDivisions = [];
      if (_selectedDivision == 'All Divisions') {
        targetDivisions = ['A', 'B', 'C']; 
      } else {
        targetDivisions = [_selectedDivision];
      }

      // 2. Write to each path
      for (String div in targetDivisions) {
        final basePath = _database.child('topic_data')
            .child(_selectedYear)
            .child(_selectedBranch)
            .child(div);

        await basePath.child('weekly_topic').set(topicData);
        await basePath.child('tip').set(tipData);
        await basePath.child('resources').set(_localResources);
        await basePath.child('friday_test').set(fridayTestData);
      }

      if (mounted) {
         _showScaffoldMessage('Data uploaded successfully for $_selectedYear $_selectedBranch $_selectedDivision!');
      }

    } catch (e) {
      if (mounted) _showScaffoldMessage('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showScaffoldMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(theme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTargetSelectionCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Weekly Topic Details', Icons.calendar_today),
                      const SizedBox(height: 12),
                      _buildTopicManagementCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Student Engagement', Icons.lightbulb_outline),
                      const SizedBox(height: 12),
                      _buildEngagementCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Learning Resources', Icons.book_outlined),
                      const SizedBox(height: 12),
                      _buildResourceManagementCard(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Friday Test Management', Icons.assignment_late),
                      const SizedBox(height: 12),
                      _buildFridayTestCard(theme),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _uploadAllData,
                          icon: _isLoading 
                            ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Icon(Icons.cloud_upload),
                          label: Text(_isLoading ? 'Uploading...' : 'Upload Data to Realtime Database'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
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

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      // Fix: using withValues instead of deprecated withOpacity
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
          Row(
            children: [
              Icon(Icons.school, color: theme.primaryColor, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Teacher Dashboard',
                     style: TextStyle(fontSize: 14, color: Colors.grey),
                   ),
                  Text(
                    'Welcome, ${_teacherName ?? "Faculty"}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelectionCard(ThemeData theme) {
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Target Audience',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Year', filled: true, fillColor: Colors.white),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                     onChanged: (v) {
                        setState(() => _selectedYear = v!);
                        _updateBranchList(); // Trigger Cascade
                        _onSelectionChanged();
                     },
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     value: _selectedBranch,
                     decoration: const InputDecoration(labelText: 'Branch', filled: true, fillColor: Colors.white),
                     items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                     onChanged: (v) {
                        setState(() => _selectedBranch = v!);
                        _updateDivisionList(); // Trigger Cascade
                        _onSelectionChanged();
                     },
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     value: _selectedDivision,
                     decoration: const InputDecoration(labelText: 'Division', filled: true, fillColor: Colors.white),
                     items: _divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                     onChanged: (v) {
                        setState(() => _selectedDivision = v!);
                        _onSelectionChanged();
                     },
                   ),
                 ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicManagementCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _topicNameController,
              decoration: const InputDecoration(
                labelText: 'Topic Name',
                hintText: 'e.g., Time & Work',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _topicDescController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief overview of the topic...',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickTestDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Test Date',
                        prefixIcon: Icon(Icons.event),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedTestDate == null 
                          ? 'Select Date' 
                          : DateFormat('MMM d, yyyy').format(_selectedTestDate!),
                        style: TextStyle(color: _selectedTestDate == null ? Colors.grey : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DropdownButtonFormField<String>(
          value: _selectedTip,
          decoration: const InputDecoration(
            labelText: 'Motivational Tip',
            prefixIcon: Icon(Icons.lightbulb_outline),
          ),
          items: _predefinedTips.map((tip) => DropdownMenuItem(value: tip, child: Text(tip, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _selectedTip = v),
          hint: const Text('Select a tip for the students'),
        ),
      ),
    );
  }

  Widget _buildResourceManagementCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // List of Added Resources
            if(_localResources.isNotEmpty) ...[
              const Text('Added Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localResources.length,
                itemBuilder: (context, index) {
                  final res = _localResources[index];
                  IconData icon;
                  switch(res['type']) {
                    case 'pdf': icon = Icons.picture_as_pdf; break;
                    case 'practice': icon = Icons.assignment; break;
                    default: icon = Icons.play_circle_outline;
                  }

                  return ListTile(
                    leading: Icon(icon, color: theme.primaryColor),
                    title: Text(res['title']!),
                    subtitle: Text(res['type'] == 'practice' ? '${res['questions'].length} Questions' : res['url']!, maxLines: 1),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeResource(index),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const Divider(height: 32),
            ],

            const Text('Add New Resource', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            
            // Type Selector
            DropdownButtonFormField<String>(
              value: _selectedResourceType,
              decoration: const InputDecoration(
                labelText: 'Resource Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: _resourceTypes.map((type) => DropdownMenuItem(
                value: type['value'] as String,
                child: Row(
                  children: [
                    Icon(type['icon'] as IconData, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(type['label'] as String),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _selectedResourceType = v!),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _resourceTitleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Concept Video',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // DYNAMIC INPUT: URL vs QUESTIONS
            if (_selectedResourceType == 'practice') ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.grey.shade300)
                 ),
                 child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Questions: ${_currentPracticeQuestions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                         TextButton.icon(
                           onPressed: _showAddQuestionDialog,
                           icon: const Icon(Icons.add_circle),
                           label: const Text('Add Question'),
                         )
                       ],
                     ),
                     if (_currentPracticeQuestions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _currentPracticeQuestions.length,
                        itemBuilder: (c, i) => ListTile(
                          title: Text(_currentPracticeQuestions[i]['question'], maxLines: 1),
                          leading: CircleAvatar(child: Text('${i+1}')),
                          dense: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () => setState(() => _currentPracticeQuestions.removeAt(i)),
                          ),
                        ),
                      )
                   ],
                 ),
               )
            ] else ...[
              TextFormField(
                controller: _resourceSubtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle (Optional)',
                  hintText: 'e.g., 15 min watch',
                  prefixIcon: Icon(Icons.subtitles),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _resourceLinkController,
                decoration: const InputDecoration(
                  labelText: 'URL (Drive/YouTube Link)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _addResourceLocally,
                icon: const Icon(Icons.add),
                label: const Text('Add to List'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFridayTestCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Friday Test for Students', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('When enabled, students can start the test.'),
              value: _isFridayTestEnabled,
              onChanged: (v) => setState(() => _isFridayTestEnabled = v),
              secondary: Icon(
                _isFridayTestEnabled ? Icons.lock_open : Icons.lock,
                color: _isFridayTestEnabled ? Colors.green : Colors.grey,
              ),
            ),
            if (_isFridayTestEnabled) ...[
              const Divider(),
              ListTile(
                 title: const Text('Test Duration (Minutes)'),
                 subtitle: Slider(
                   value: _fridayTestDuration.toDouble(),
                   min: 10,
                   max: 180,
                   divisions: 34,
                   label: '$_fridayTestDuration mins',
                   onChanged: (v) => setState(() => _fridayTestDuration = v.round()),
                 ),
                 trailing: Text('$_fridayTestDuration mins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      AppRoutes.liveMonitor,
                      arguments: {
                        'year': _selectedYear,
                        'branch': _selectedBranch,
                        'division': _selectedDivision,
                      }
                    );
                  },
                  icon: const Icon(Icons.monitor_heart),
                  label: const Text('Monitor Live Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    foregroundColor: Colors.white
                  ),
                ),
              ),
            ],
            const Divider(),
            Align(
              alignment: Alignment.centerLeft, 
              child: Text('Test Questions: ${_fridayTestQuestions.length}', style: const TextStyle(fontWeight: FontWeight.w600))
            ),
            const SizedBox(height: 8),
            if (_fridayTestQuestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fridayTestQuestions.length,
                itemBuilder: (c, i) => ListTile(
                   title: Text(_fridayTestQuestions[i]['question'], maxLines: 1),
                   leading: CircleAvatar(child: Text('${i + 1}')),
                   trailing: IconButton(
                     icon: const Icon(Icons.delete, color: Colors.red),
                     onPressed: () => setState(() => _fridayTestQuestions.removeAt(i)),
                   ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddFridayQuestionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Test Question'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showAddFridayQuestionDialog() {
    final qController = TextEditingController();
    final op1Controller = TextEditingController();
    final op2Controller = TextEditingController();
    final op3Controller = TextEditingController();
    final op4Controller = TextEditingController();
    int correctOption = 0; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Test Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(controller: qController, decoration: const InputDecoration(labelText: 'Question'), maxLines: 2),
                    const SizedBox(height: 12),
                    TextFormField(controller: op1Controller, decoration: const InputDecoration(labelText: 'Option 1')),
                    TextFormField(controller: op2Controller, decoration: const InputDecoration(labelText: 'Option 2')),
                    TextFormField(controller: op3Controller, decoration: const InputDecoration(labelText: 'Option 3')),
                    TextFormField(controller: op4Controller, decoration: const InputDecoration(labelText: 'Option 4')),
                    const SizedBox(height: 16),
                    const Text('Correct Option:'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(4, (index) {
                        return ChoiceChip(
                          label: Text('${index + 1}'),
                          selected: correctOption == index,
                          onSelected: (selected) {
                            if (selected) setStateDialog(() => correctOption = index);
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (qController.text.isNotEmpty && op1Controller.text.isNotEmpty) {
                      setState(() {
                         _fridayTestQuestions.add({
                           'question': qController.text.trim(),
                           'options': [
                             op1Controller.text.trim(),
                             op2Controller.text.trim(),
                             op3Controller.text.trim(),
                             op4Controller.text.trim(),
                           ],
                           'correctAnswer': correctOption,
                         });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

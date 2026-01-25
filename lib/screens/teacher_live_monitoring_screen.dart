import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherLiveMonitoringScreen extends StatefulWidget {
  const TeacherLiveMonitoringScreen({super.key});

  @override
  State<TeacherLiveMonitoringScreen> createState() => _TeacherLiveMonitoringScreenState();
}

class _TeacherLiveMonitoringScreenState extends State<TeacherLiveMonitoringScreen> {
  final _database = FirebaseDatabase.instance.ref();
  
  String _year = 'FE';
  String _branch = 'CO';
  String _division = 'A';
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _year = args['year'] ?? 'FE';
        _branch = args['branch'] ?? 'CO';
        _division = args['division'] ?? 'A';
      }
      _isLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllDivisions = _division == 'All Divisions';
    final path = isAllDivisions 
        ? 'friday_test_live/$_year/$_branch' 
        : 'friday_test_live/$_year/$_branch/$_division';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('Live Test Monitor', style: TextStyle(fontSize: 18)),
             Text('$_year $_branch $_division', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: StreamBuilder(
                stream: _database.child(path).onValue,
                builder: (context, snapshot) {
                   int active = 0;
                   int violation = 0;
                   int submitted = 0;
                   
                   if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                      final rawData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      
                      // Flatten if All Divisions
                      final List<Map> allStudents = [];
                      if (isAllDivisions) {
                        rawData.forEach((div, studentsMap) {
                          if (studentsMap is Map) {
                            studentsMap.forEach((k, v) => allStudents.add(v as Map));
                          }
                        });
                      } else {
                        rawData.forEach((k, v) => allStudents.add(v as Map));
                      }

                      for (var v in allStudents) {
                        final status = v['status'];
                        if (status == 'ACTIVE') active++;
                        else if (status == 'VIOLATION_DETECTED') violation++;
                        else if (status == 'SUBMITTED') submitted++;
                      }
                   }
                   
                   return Row(
                     children: [
                       _buildCountBadge(active, Colors.green, 'Active'),
                       const SizedBox(width: 8),
                       _buildCountBadge(violation, Colors.red, 'Violations'),
                       const SizedBox(width: 8),
                       _buildCountBadge(submitted, Colors.grey, 'Done'),
                     ],
                   );
                },
              ),
            ),
          )
        ],
      ),
      body: StreamBuilder(
        stream: _database.child(path).onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('No students are currently taking the test.'));
          }

          final rawData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> students = [];

          if (isAllDivisions) {
             // Handle Nested Structure: Division -> StudentID -> Data
             rawData.forEach((divKey, divData) {
               if (divData is Map) {
                 divData.forEach((studentId, studentData) {
                   final val = Map<String, dynamic>.from(studentData as Map);
                   val['id'] = studentId;
                   val['div'] = divKey; // Optional: Show Div
                   students.add(val);
                 });
               }
             });
          } else {
             // Normal Structure: StudentID -> Data
             students = rawData.entries.map((e) {
                final val = Map<String, dynamic>.from(e.value as Map);
                val['id'] = e.key;
                return val;
             }).toList();
          }

          // Sort: Violations first, then Active, then Submitted
          students.sort((a, b) {
            final statusOrder = {'VIOLATION_DETECTED': 0, 'ACTIVE': 1, 'SUBMITTED': 2};
            return (statusOrder[a['status']] ?? 3).compareTo(statusOrder[b['status']] ?? 3);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final status = student['status'] ?? 'UNKNOWN';
              final violations = student['violationCount'] ?? 0;
              final score = student['score'] ?? 0;
              final solved = student['solved'] ?? 0;
              final name = student['name'] ?? student['id'];

              Color color;
              IconData icon;
              String msg;

              switch (status) {
                case 'VIOLATION_DETECTED':
                  color = Colors.red.shade100;
                  icon = Icons.warning;
                  msg = 'Tab Switch Detected!';
                  break;
                case 'SUBMITTED':
                  color = Colors.grey.shade200;
                  icon = Icons.check_circle;
                  msg = 'Test Submitted';
                  break;
                default:
                  color = Colors.green.shade50;
                  icon = Icons.edit;
                  msg = 'Active';
              }

              return Card(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1)),
                          Icon(icon, color: status == 'VIOLATION_DETECTED' ? Colors.red : Colors.green),
                        ],
                      ),
                      const Divider(),
                      if (status == 'VIOLATION_DETECTED') ...[
                         Text(student['lastViolationMessage'] ?? msg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                         Text('Violations: $violations', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ] else ...[
                        Text(msg, style: TextStyle(color: Colors.grey[700])),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [Text('$solved', style: const TextStyle(fontWeight: FontWeight.bold)), const Text('Solved', style: TextStyle(fontSize: 10))]),
                          Column(children: [Text('$score', style: const TextStyle(fontWeight: FontWeight.bold)), const Text('Score', style: TextStyle(fontSize: 10))]),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text('$count $label', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

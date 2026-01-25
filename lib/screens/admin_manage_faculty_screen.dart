import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminManageFacultyScreen extends StatefulWidget {
  const AdminManageFacultyScreen({super.key});

  @override
  State<AdminManageFacultyScreen> createState() => _AdminManageFacultyScreenState();
}

class _AdminManageFacultyScreenState extends State<AdminManageFacultyScreen> {
  final _database = FirebaseDatabase.instance.ref();
  
  // Selection Metadata
  final List<String> _years = ['FE', 'SE', 'TE', 'BE'];
  final List<String> _branches = ['CO', 'IT', 'AIDS'];
  final List<String> _divisions = ['A', 'B', 'C', 'All Divisions'];

  void _showPermissionDialog(String teacherId, String teacherName, List<dynamic> currentAccess) {
    List<String> updatedAccess = List<String>.from(currentAccess.map((e) => e.toString()));
    
    // Temp Selection
    String selYear = _years.first;
    String selBranch = _branches.first;
    String selDiv = _divisions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Manage Access: $teacherName'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Permissions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  updatedAccess.isEmpty 
                    ? const Text('No access assigned.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    : Wrap(
                        spacing: 8.0,
                        children: updatedAccess.map((access) => Chip(
                          label: Text(access),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setDialogState(() {
                              updatedAccess.remove(access);
                            });
                          },
                        )).toList(),
                      ),
                  const Divider(height: 32),
                  const Text('Add New Access:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selYear,
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setDialogState(() => selYear = v!),
                          decoration: const InputDecoration(labelText: 'Year', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selBranch,
                          items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setDialogState(() => selBranch = v!),
                          decoration: const InputDecoration(labelText: 'Branch', isDense: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selDiv,
                          items: _divisions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setDialogState(() => selDiv = v!),
                          decoration: const InputDecoration(labelText: 'Division', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final newAccess = '$selYear-$selBranch-$selDiv';
                          if (!updatedAccess.contains(newAccess)) {
                            setDialogState(() {
                              updatedAccess.add(newAccess);
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
              ElevatedButton(
                child: const Text('Save Changes'),
                onPressed: () async {
                  await _database.child('teachers').child(teacherId).child('access_list').set(updatedAccess);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions Updated')));
                  }
                },
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculty Permissions')),
      body: StreamBuilder(
        stream: _database.child('teachers').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final teachers = data.entries.map((e) {
            final val = e.value as Map<dynamic, dynamic>;
            return {
              'id': e.key,
              'name': val['name'] ?? 'Unknown',
              'access_list': val['access_list'] ?? [],
            };
          }).toList();

          if (teachers.isEmpty) return const Center(child: Text('No teachers registered yet.'));

          return ListView.separated(
            itemCount: teachers.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final t = teachers[index];
              final accessList = (t['access_list'] as List<dynamic>?) ?? [];
              
              return ListTile(
                leading: CircleAvatar(child: Text((t['name'] as String)[0].toUpperCase())),
                title: Text('${t['name']} (${t['id']})'),
                subtitle: Text(
                  accessList.isEmpty 
                    ? 'No classes assigned' 
                    : 'Access: ${accessList.join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.edit_note),
                onTap: () => _showPermissionDialog(t['id'], t['name'], accessList),
              );
            },
          );
        },
      ),
    );
  }
}

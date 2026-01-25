class UserModel {
  final String uid;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  final String name;
  final String? division; // e.g. "A", "B"
  final String? year; // e.g. "SE", "TE", "BE"

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.division,
    this.year,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      name: data['name'] ?? 'Unknown',
      division: data['division'],
      year: data['year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'division': division,
      'year': year,
    };
  }
}

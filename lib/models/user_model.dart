class UserModel {
  final String uid;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  final String name;
  final String? division;
  final String? year;
  final bool isVolunteer;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.division,
    this.year,
    this.isVolunteer = false,
    this.latitude,
    this.longitude,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      name: data['name'] ?? 'Unknown',
      division: data['division'],
      year: data['year'],
      isVolunteer: data['isVolunteer'] ?? false,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      lastSeen: data['lastSeen'] != null ? DateTime.parse(data['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'division': division,
      'year': year,
      'isVolunteer': isVolunteer,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}

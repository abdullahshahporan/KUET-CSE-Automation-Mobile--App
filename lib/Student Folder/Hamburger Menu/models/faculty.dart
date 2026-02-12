class Faculty {
  final String fullName;
  final String designation;
  final String? email;
  final String? phone;
  final String? room;
  final bool isOnLeave;

  Faculty({
    required this.fullName,
    required this.designation,
    this.email,
    this.phone,
    this.room,
    this.isOnLeave = false,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    final email = (profiles is Map) ? profiles['email'] as String? : null;
    final room = json['room_no']?.toString() ?? json['office_room']?.toString();

    return Faculty(
      fullName: json['full_name'] ?? '',
      designation: json['designation'] ?? 'LECTURER',
      email: email,
      phone: json['phone']?.toString(),
      room: room,
      isOnLeave: json['is_on_leave'] == true,
    );
  }

  String get initial => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  String get formattedDesignation {
    return designation
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  int get designationPriority {
    const order = {
      'PROFESSOR': 1,
      'ASSOCIATE_PROFESSOR': 2,
      'ASSISTANT_PROFESSOR': 3,
      'LECTURER': 4,
    };
    return order[designation.toUpperCase()] ?? 5;
  }

  static int compare(Faculty a, Faculty b) {
    // On-leave teachers go to bottom
    if (a.isOnLeave != b.isOnLeave) {
      return a.isOnLeave ? 1 : -1;
    }
    
    // Sort by designation priority
    final designationCompare = a.designationPriority.compareTo(b.designationPriority);
    if (designationCompare != 0) return designationCompare;
    
    // Then by name
    return a.fullName.compareTo(b.fullName);
  }
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String role;
  final bool isApproved;
  final DateTime? dob;
  final String? gender;
  final int unreadCount;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    required this.role,
    required this.isApproved,
    this.dob,
    this.gender,
    this.unreadCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? "",
      firstName: json['firstName'] ?? "",
      lastName: json['lastName'] ?? "",
      phone: json['phone'] ?? "",
      email: json['email'],
      role: json['role'] ?? "",
      isApproved: json['isApproved'] ?? false,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob'].toString()) : null,
      gender: json['gender'],
      unreadCount: (json['unreadCount'] ?? json['unread_count'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "email": email,
        "role": role,
        "isApproved": isApproved,
        "dob": dob?.toIso8601String(),
        "gender": gender,
        "unreadCount": unreadCount,
      };
}

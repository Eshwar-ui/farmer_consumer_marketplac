enum UserRole { farmer, consumer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String location;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.location,
    this.profileImageUrl,
  });

  // Factory method to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: _parseRole(json['role']),
      location: json['location'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role == UserRole.farmer ? 'farmer' : 'consumer',
      'location': location,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Parse role from string
  static UserRole _parseRole(String? roleStr) {
    if (roleStr?.toLowerCase() == 'farmer') {
      return UserRole.farmer;
    }
    return UserRole.consumer;
  }

  // Create a copy of the UserModel with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? location,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
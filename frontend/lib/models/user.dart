// User types matching backend
enum UserType {
  individual,
  wholesale,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.individual:
        return 'Individual';
      case UserType.wholesale:
        return 'Wholesale';
    }
  }

  String get apiValue {
    switch (this) {
      case UserType.individual:
        return 'individual';
      case UserType.wholesale:
        return 'wholesale';
    }
  }

  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'individual':
        return UserType.individual;
      case 'wholesale':
        return UserType.wholesale;
      default:
        return UserType.individual;
    }
  }
}

// User model matching backend structure
class User {
  final String id;
  final String email;
  final String name;
  final UserType type;
  final double rebateCredits;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.type,
    this.rebateCredits = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      type: UserTypeExtension.fromString(json['type'] ?? 'individual'),
      rebateCredits: (json['rebateCredits'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'type': type.apiValue,
      'rebateCredits': rebateCredits,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? type,
    double? rebateCredits,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      type: type ?? this.type,
      rebateCredits: rebateCredits ?? this.rebateCredits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, type: ${type.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ type.hashCode;
}

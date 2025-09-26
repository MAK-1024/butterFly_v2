import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/themes/roles.dart';

class UserModel {
  final String id;
  final String email;
  final List<String> role;
  final String? userName;
  final String? phone;
  final bool isDisabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool forceLogout;

  bool get isAdmin => role.contains(AppRoles.admin);
  bool get isCoordinator => role.contains(AppRoles.coordinator);
  bool get isDelivery => role.contains(AppRoles.delivery);
  bool get isRegularUser => role.contains(AppRoles.user);

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.userName,
    this.phone,
    this.isDisabled = false,
    this.createdAt,
    this.updatedAt,
    this.forceLogout = false,

  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final List<String> parsedRoles = (map['role'] is List)
        ? List<String>.from(map['role'])
        : [map['role'] ?? AppRoles.user]; // ✅ Fallback for old data

    return UserModel(
      id: id,
      email: map['email'] ?? '',
      role: parsedRoles,
      userName: map['userName'],
      phone: map['phone'],
      isDisabled: map['isDisabled'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      forceLogout: map['forceLogout'] ?? false,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'userName': userName,
      'phone': phone,
      'isDisabled': isDisabled,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'forceLogout': forceLogout,

    };
  }

  UserModel copyWith({
    String? email,
    List<String>? role,
    String? userName,
    String? phone,
    bool? isDisabled,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
      isDisabled: isDisabled ?? this.isDisabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

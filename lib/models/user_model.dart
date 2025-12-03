import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String contact;
  final String idNumber;
  final String preferredContactMethod;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.contact,
    required this.idNumber,
    required this.preferredContactMethod,
    required this.role,
    required this.createdAt,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'contact': contact,
      'idNumber': idNumber,
      'preferredContactMethod': preferredContactMethod,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create UserModel from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      idNumber: map['idNumber'] ?? '',
      preferredContactMethod: map['preferredContactMethod'] ?? 'email',
      role: UserRoleExtension.fromString(map['role'] ?? 'guest'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? contact,
    String? idNumber,
    String? preferredContactMethod,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      idNumber: idNumber ?? this.idNumber,
      preferredContactMethod: preferredContactMethod ?? this.preferredContactMethod,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

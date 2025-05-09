import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("User data not found in Firestore for document ${snapshot.id}");
    }
    return UserModel(
      uid: snapshot.id,
      name: data['name'] as String? ?? 'No Name',
      email: data['email'] as String? ?? 'No Email',
      role: data['role'] as String? ?? 'buyer',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, role, createdAt];
}

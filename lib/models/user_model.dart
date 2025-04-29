import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
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
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, createdAt];
}

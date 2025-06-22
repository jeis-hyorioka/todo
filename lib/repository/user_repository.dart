import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/model/user_profile.dart';

class UserRepository {
  final FirebaseFirestore firestore;
  UserRepository({required this.firestore});

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data());
  }

  Future<void> updateNickname(String uid, String nickname) async {
    await firestore.collection('users').doc(uid).set({
      'nickname': nickname,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

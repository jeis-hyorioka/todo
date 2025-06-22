import 'package:cloud_firestore/cloud_firestore.dart';

class InviteRepository {
  final FirebaseFirestore firestore;
  InviteRepository({required this.firestore});

  Future<String> generateInviteCode(String listId) async {
    final code = _randomCode(8);
    await firestore.collection('invites').doc(code).set({
      'listId': listId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<String?> joinByInviteCode(String code, String userId) async {
    final doc = await firestore.collection('invites').doc(code).get();
    if (doc.exists) {
      final listId = doc['listId'] as String?;
      if (listId != null) {
        await firestore.collection('lists').doc(listId).update({
          'members': FieldValue.arrayUnion([userId]),
        });
        await doc.reference.delete();
        return listId;
      }
    }
    return null;
  }

  String _randomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (i) => chars[(rand + i) % chars.length]).join();
  }
}

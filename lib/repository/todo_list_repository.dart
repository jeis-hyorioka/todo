import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/model/todo_list.dart';

class TodoListRepository {
  final FirebaseFirestore firestore;
  TodoListRepository({required this.firestore});

  Stream<List<TodoList>> watchLists(String userId) {
    return firestore
        .collection('lists')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TodoList.fromDoc(doc)).toList());
  }

  Future<String> createList(String name, String userId) async {
    final doc = await firestore.collection('lists').add({
      'name': name,
      'members': [userId],
    });
    return doc.id;
  }

  Future<void> joinList(String listId, String userId) async {
    await firestore.collection('lists').doc(listId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> deleteList(String listId) async {
    await firestore.collection('lists').doc(listId).delete();
  }

  Future<void> leaveList(String listId, String userId) async {
    await firestore.collection('lists').doc(listId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }
}

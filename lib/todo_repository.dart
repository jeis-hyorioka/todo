import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String title;
  final bool isDone;

  Todo({required this.id, required this.title, required this.isDone});

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
    };
  }
}

class TodoRepository {
  final FirebaseFirestore firestore;
  final String listId;

  TodoRepository({required this.firestore, required this.listId})
      : assert(listId.isNotEmpty, 'listId must not be empty');

  CollectionReference get _todosRef => firestore
      .collection('lists')
      .doc(listId)
      .collection('todos');

  Stream<List<Todo>> watchTodos() {
    return _todosRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList());
  }

  Future<void> addTodo(String title) async {
    await _todosRef.add({'title': title, 'isDone': false});
  }

  Future<void> deleteTodo(String id) async {
    await _todosRef.doc(id).delete();
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    await _todosRef.doc(id).update({'isDone': isDone});
  }
}

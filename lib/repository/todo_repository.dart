import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/model/todo.dart';

class TodoRepository {
  final FirebaseFirestore firestore;
  final String listId;

  TodoRepository({required this.firestore, required this.listId})
    : assert(listId.isNotEmpty, 'listId must not be empty');

  CollectionReference get _todosRef =>
      firestore.collection('lists').doc(listId).collection('todos');

  Stream<List<Todo>> watchTodos() {
    return _todosRef
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList(),
        );
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

  Future<void> updateOrder(String id, int order) async {
    await _todosRef.doc(id).update({'order': order});
  }
}

class DummyTodoRepository extends TodoRepository {
  DummyTodoRepository()
    : super(firestore: FirebaseFirestore.instance, listId: 'dummy');

  @override
  Stream<List<Todo>> watchTodos() => const Stream.empty();
  @override
  Future<void> addTodo(String title) async {}
  @override
  Future<void> deleteTodo(String id) async {}
  @override
  Future<void> toggleTodo(String id, bool isDone) async {}
  @override
  Future<void> updateOrder(String id, int order) async {}
}

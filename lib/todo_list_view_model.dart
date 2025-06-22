import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/todo_list.dart';
import 'todo_list_repository.dart';
import 'main.dart';

final todoListViewModelProvider = StateNotifierProvider.autoDispose<StateNotifier<AsyncValue<List<TodoList>>>, AsyncValue<List<TodoList>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(userIdProvider); // 認証Providerと連携
  final repository = TodoListRepository(firestore: firestore);
  return userId != null && userId.isNotEmpty
      ? TodoListViewModel(repository, userId)
      : DummyTodoListViewModel();
});

class TodoListViewModel extends StateNotifier<AsyncValue<List<TodoList>>> {
  final TodoListRepository repository;
  final String userId;
  late final Stream<List<TodoList>> _listStream;
  StreamSubscription<List<TodoList>>? _subscription;

  TodoListViewModel(this.repository, this.userId) : super(const AsyncValue.loading()) {
    _listStream = repository.watchLists(userId);
    _subscription = _listStream.listen((lists) {
      state = AsyncValue.data(lists);
    }, onError: (e, st) {
      state = AsyncValue.error(e, st);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<String?> createList(String name) async {
    try {
      final id = await repository.createList(name, userId);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> joinList(String listId) async {
    try {
      await repository.joinList(listId, userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class DummyTodoListViewModel extends StateNotifier<AsyncValue<List<TodoList>>> {
  DummyTodoListViewModel() : super(const AsyncValue.data([]));
}

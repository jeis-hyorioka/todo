import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'todo_list_repository.dart' as repo;
import 'main.dart';

final todoListViewModelProvider = StateNotifierProvider.autoDispose<TodoListViewModel, AsyncValue<List<repo.TodoList>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(userIdProvider); // 認証Providerと連携
  final repository = repo.TodoListRepository(firestore: firestore);
  return TodoListViewModel(repository, userId!);
});

class TodoListViewModel extends StateNotifier<AsyncValue<List<repo.TodoList>>> {
  final repo.TodoListRepository repository;
  final String userId;
  late final Stream<List<repo.TodoList>> _listStream;
  StreamSubscription<List<repo.TodoList>>? _subscription;

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

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_repository.dart' as repo;
import 'main.dart';

final todoViewModelProvider = StateNotifierProvider.autoDispose<TodoViewModel, AsyncValue<List<repo.Todo>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final listId = ref.watch(listIdProvider);
  if (listId == null || listId.isEmpty) {
    // ダミーViewModel（空リストのみ返す）
    return TodoViewModel.empty();
  }
  final repository = repo.TodoRepository(
    firestore: firestore,
    listId: listId,
  );
  return TodoViewModel(repository);
});

class TodoViewModel extends StateNotifier<AsyncValue<List<repo.Todo>>> {
  final repo.TodoRepository? repository;
  StreamSubscription<List<repo.Todo>>? _subscription;

  // 通常用
  TodoViewModel(this.repository) : super(const AsyncValue.loading()) {
    if (repository != null) {
      _subscription = repository!.watchTodos().listen(
        (todos) => state = AsyncValue.data(todos),
        onError: (e, st) => state = AsyncValue.error(e, st),
      );
    }
  }
  // ダミー用
  TodoViewModel.empty() : repository = null, _subscription = null, super(const AsyncValue.data([]));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addTodo(String title) async {
    if (repository == null) return;
    try {
      await repository!.addTodo(title);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTodo(String id) async {
    if (repository == null) return;
    try {
      await repository!.deleteTodo(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    if (repository == null) return;
    try {
      await repository!.toggleTodo(id, isDone);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 仮のProvider（本来は認証・リスト選択状態から取得）
// final userIdProvider = Provider<String>((ref) => 'dummyUserId');
// final listIdProvider = Provider<String>((ref) => 'defaultListId');

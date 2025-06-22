import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/main.dart';
import '../model/todo.dart';
import '../repository/todo_repository.dart';

final todoViewModelProvider = StateNotifierProvider.autoDispose<TodoViewModel, AsyncValue<List<Todo>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final listId = ref.watch(listIdProvider);
  return listId != null && listId.isNotEmpty
      ? TodoViewModel(TodoRepository(firestore: firestore, listId: listId))
      : DummyTodoViewModel();
});

class TodoViewModel extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository repository;
  StreamSubscription<List<Todo>>? _subscription;

  // 通常用
  TodoViewModel(this.repository) : super(const AsyncValue.loading()) {
    _subscription = repository.watchTodos().listen(
      (todos) => state = AsyncValue.data(todos),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }
  // ダミー用
  TodoViewModel.empty()
      : repository = DummyTodoRepository(),
        _subscription = null,
        super(const AsyncValue.data([]));

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addTodo(String title) async {
    try {
      await repository.addTodo(title);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await repository.deleteTodo(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    try {
      await repository.toggleTodo(id, isDone);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderTodos(int oldIndex, int newIndex) async {
    // Firestoreにorderフィールドを追加して順序を管理する実装例
    final todos = state.value ?? [];
    if (oldIndex < newIndex) newIndex--;
    final updated = [...todos];
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    // Firestoreに新しい順序を反映
    for (int i = 0; i < updated.length; i++) {
      await repository.updateOrder(updated[i].id, i);
    }
    // ローカル状態も即時反映
    state = AsyncValue.data(updated);
  }
}

class DummyTodoViewModel extends TodoViewModel {
  DummyTodoViewModel() : super(DummyTodoRepository());
  @override
  Future<void> addTodo(String title) async {}
  @override
  Future<void> deleteTodo(String id) async {}
  @override
  Future<void> toggleTodo(String id, bool isDone) async {}
}

// 仮のProvider（本来は認証・リスト選択状態から取得）
// final userIdProvider = Provider<String>((ref) => 'dummyUserId');
// final listIdProvider = Provider<String>((ref) => 'defaultListId');

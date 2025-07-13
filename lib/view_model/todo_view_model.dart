import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/todo_repository.dart';
import '../main.dart';
import '../model/todo.dart';

final todoViewModelProvider =
    StateNotifierProvider.autoDispose<TodoViewModel, AsyncValue<List<Todo>>>((
      ref,
    ) {
      final firestore = ref.watch(firestoreProvider);
      final listId = ref.watch(listIdProvider);
      return listId != null && listId.isNotEmpty
          ? TodoViewModel(TodoRepository(firestore: firestore, listId: listId))
          : DummyTodoViewModel();
    });

class TodoViewModel extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository repository;
  StreamSubscription<List<Todo>>? _subscription;
  bool _isLocallyUpdating = false;

  // 通常用
  TodoViewModel(this.repository) : super(const AsyncValue.loading()) {
    _subscription = repository.watchTodos().listen((todos) {
      if (!_isLocallyUpdating) {
        state = AsyncValue.data(todos);
      }
    }, onError: (e, st) => state = AsyncValue.error(e, st));
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
    _isLocallyUpdating = true;
    final todos = state.value ?? [];
    if (oldIndex < newIndex) {
      newIndex--;
    }
    final updated = [...todos];
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    // ローカル状態を先に更新してUIに即時反映（楽観的UI）
    state = AsyncValue.data(updated);

    // Firestoreに新しい順序を反映
    try {
      // 更新処理を並列で実行して効率化
      final List<Future<void>> updateFutures = [];
      for (int i = 0; i < updated.length; i++) {
        updateFutures.add(repository.updateOrder(updated[i].id, i));
      }
      await Future.wait(updateFutures);
    } catch (e, st) {
      // エラーが発生した場合は、元の状態に戻すなどのエラーハンドリングを行う
      state = AsyncValue.error(e, st);
    } finally {
      // 処理が完了したら、ストリームからの更新を受け入れるようにする
      // これにより、DBの最新の状態がUIに反映され、ローカルの状態との整合性が検証される
      _isLocallyUpdating = false;
    }
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

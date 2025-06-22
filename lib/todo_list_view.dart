import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_view_model.dart';
import 'main.dart';
import 'todo_add_button.dart';
import 'todo_detail_sheet.dart';
import 'models/todo_list.dart';

class TodoListView extends ConsumerWidget {
  const TodoListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoViewModelProvider);
    final listId = ref.watch(listIdProvider);
    final isListSelected = listId != null && listId.isNotEmpty;
    return todoState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('エラー: $e')),
      data: (todos) => Stack(
        children: [
          Column(
            children: [
              if (!isListSelected)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('リストを選択/作成してください', style: TextStyle(color: Colors.grey)),
                ),
              if (isListSelected)
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: todos.length,
                    onReorder: (oldIndex, newIndex) async {
                      await ref.read(todoViewModelProvider.notifier).reorderTodos(oldIndex, newIndex);
                    },
                    buildDefaultDragHandles: true,
                    proxyDecorator: (child, index, animation) {
                      // ドラッグ中もshadowを消す
                      return Material(
                        color: Colors.transparent,
                        child: child,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      );
                    },
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return Card(
                        key: ValueKey(todo.id),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: todo.isDone,
                            onChanged: (checked) {
                              ref.read(todoViewModelProvider.notifier).toggleTodo(todo.id, !(todo.isDone));
                            },
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isDone ? TextDecoration.lineThrough : null,
                              color: todo.isDone ? Colors.grey : null,
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => TodoDetailSheet(title: todo.title, todoId: todo.id),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          if (isListSelected)
            const Positioned(
              bottom: 24,
              right: 24,
              child: TodoAddButton(),
            ),
        ],
      ),
    );
  }
}

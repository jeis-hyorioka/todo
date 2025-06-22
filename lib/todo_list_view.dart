import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_view_model.dart';
import 'main.dart';

class TodoListView extends ConsumerWidget {
  const TodoListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoViewModelProvider);
    final listId = ref.watch(listIdProvider);
    final isListSelected = listId != null && listId.isNotEmpty;
    final TextEditingController addController = TextEditingController();
    return todoState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('エラー: $e')),
      data: (todos) => Column(
        children: [
          if (!isListSelected)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('リストを選択/作成してください', style: TextStyle(color: Colors.grey)),
            ),
          if (isListSelected)
            Expanded(
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return ListTile(
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref.read(todoViewModelProvider.notifier).deleteTodo(todo.id);
                      },
                    ),
                  );
                },
              ),
            ),
          if (isListSelected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addController,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          ref.read(todoViewModelProvider.notifier).addTodo(value.trim());
                          addController.clear();
                        }
                      },
                      decoration: const InputDecoration(hintText: 'タスクを追加'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final value = addController.text.trim();
                      if (value.isNotEmpty) {
                        ref.read(todoViewModelProvider.notifier).addTodo(value);
                        addController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

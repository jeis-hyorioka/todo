import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_view_model.dart';

class TodoAddButton extends ConsumerWidget {
  const TodoAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      shape: const CircleBorder(),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            final TextEditingController inputController = TextEditingController();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('タスクを追加', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: inputController,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'タスクのタイトル'),
                    onSubmitted: (value) {
                      final v = value.trim();
                      if (v.isNotEmpty) {
                        ref.read(todoViewModelProvider.notifier).addTodo(v);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final v = inputController.text.trim();
                        if (v.isNotEmpty) {
                          ref.read(todoViewModelProvider.notifier).addTodo(v);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('追加'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

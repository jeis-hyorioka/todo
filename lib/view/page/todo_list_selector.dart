import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/main.dart';
import 'package:todo/model/todo_list.dart';
import 'package:todo/repository/todo_list_repository.dart';
import 'package:todo/view_model/todo_list_view_model.dart';

class TodoListSelectorSheet extends ConsumerWidget {
  final String? selectedListId;
  final ValueChanged<TodoList> onSelected;
  final void Function(TodoList)? onSettings;
  const TodoListSelectorSheet({Key? key, required this.selectedListId, required this.onSelected, this.onSettings}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(todoListViewModelProvider);
    return listState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('エラー: $e')),
      data: (lists) => SafeArea(
        top: false, // 上部はSafeAreaを無効化
        bottom: true, // 下部のみ有効
        child: Padding(
          padding: const EdgeInsets.only(top: 32), // 上部に余白を追加
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Todo List List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: lists.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      title: Text(list.name),
                      selected: list.id == selectedListId,
                      onTap: () {
                        onSelected(list);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('リストを追加'),
                    onPressed: () async {
                      final controller = TextEditingController();
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('新しいリストを作成'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(hintText: 'リスト名'),
                            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                              child: const Text('作成'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        final listVM = ref.read(todoListViewModelProvider.notifier);
                        if (listVM is TodoListViewModel) {
                          final id = await listVM.createList(result);
                          if (id != null) {
                            ref.read(listIdProvider.notifier).state = id;
                            Navigator.of(context).pop(); // 追加後にシートを閉じる
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

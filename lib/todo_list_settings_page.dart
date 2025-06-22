import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';
import 'todo_list_repository.dart' as repo;

class TodoListSettingsPage extends ConsumerStatefulWidget {
  final repo.TodoList list;
  const TodoListSettingsPage({Key? key, required this.list}) : super(key: key);

  @override
  ConsumerState<TodoListSettingsPage> createState() => _TodoListSettingsPageState();
}

class _TodoListSettingsPageState extends ConsumerState<TodoListSettingsPage> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.list.name);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Scaffold(
      appBar: AppBar(title: const Text('リスト設定')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('リスト名', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'リスト名を入力'),
              onSubmitted: (value) {
                // TODO: Firestoreでリスト名を更新する処理を追加
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final userId = ref.read(userIdProvider);
                if (userId == null) return;
                final repo.TodoListRepository repository = repo.TodoListRepository(firestore: FirebaseFirestore.instance);
                if (list.members.length <= 1) {
                  // 参加者が自分だけ→リストごと削除
                  await repository.deleteList(list.id);
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ToDoリストを削除しました')),
                    );
                  }
                } else {
                  // 他にも参加者がいる→自分だけ退出
                  await repository.leaveList(list.id, userId);
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ToDoリストから抜けました')),
                    );
                  }
                }
              },
              label: const Text('このリストを削除'),
            ),
            const SizedBox(height: 32),
            const Text('参加者一覧', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...list.members.map((m) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(m),
                )),
          ],
        ),
      ),
    );
  }
}

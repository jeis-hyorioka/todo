import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/main.dart';
import 'package:todo/repository/todo_list_repository.dart' as repo;
import 'package:todo/model/todo_list.dart';
import 'package:todo/view_model/invite_view_model.dart';
import 'package:todo/view/page/invite_code_issued_dialog.dart';

class TodoListSettingsPage extends ConsumerStatefulWidget {
  final TodoList list;
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
      body: Stack(
        children: [
          Padding(
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
                const SizedBox(height: 32),
                const Text('参加者一覧', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // 参加者一覧のnicknameをFirestoreから取得して表示
                FutureBuilder<List<Map<String, String>>>(
                  future: Future.wait(list.members.map((uid) async {
                    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                    final nickname = doc.data()?['nickname'] ?? '未登録';
                    return {'uid': uid, 'nickname': nickname};
                  })),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final members = snapshot.data!;
                    return Column(
                      children: members.map((m) => ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(m['nickname'] ?? ''),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link, color: Colors.white),
                      label: const Text('招待コードを発行', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 48),
                        shape: const StadiumBorder(), // 丸みを最大化
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final inviteVM = ref.read(inviteViewModelProvider.notifier);
                        final code = await inviteVM.generateInviteCode(list.id);
                        if (context.mounted && code != null) {
                          showDialog(
                            context: context,
                            builder: (context) => InviteCodeIssuedDialog(code: code),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 画面最下部に削除ボタン
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('このリストを削除', style: TextStyle(color: Colors.red)),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

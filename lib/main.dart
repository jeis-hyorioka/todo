import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/firebase_options.dart';
import 'package:todo/side_menu.dart';
import 'package:todo/todo_list_selector.dart';
import 'package:todo/invite_code_dialog.dart';
import 'package:todo/invite_code_issued_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_list_view.dart';
import 'todo_view_model.dart';
import 'todo_list_view_model.dart';
import 'invite_view_model.dart';
import 'todo_list_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern ToDo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        textTheme: GoogleFonts.notoSansJpTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
          iconTheme: IconThemeData(color: Colors.teal),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
final userIdProvider = Provider<String?>((ref) {
  final user = ref.watch(firebaseAuthUserProvider).value;
  return user?.uid;
});
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
// main.dartでグローバルにlistIdProviderを定義
final listIdProvider = StateProvider<String?>((ref) => null);

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firebaseAuthUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (user) {
        if (user != null) {
          return MyHomePage(user: user);
        }
        return const SignInPage();
      },
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  Future<void> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ToDoアプリ', style: GoogleFonts.notoSansJp(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.login, color: Colors.red),
              label: const Text('Googleでログイン'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final User user;
  const MyHomePage({super.key, required this.user});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Todo {
  String id;
  String title;
  bool isDone;
  Todo({required this.id, required this.title, this.isDone = false});
  factory Todo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
    );
  }
}

class TodoList {
  String id;
  String name;
  List<String> members;
  TodoList({required this.id, required this.name, required this.members});
  factory TodoList.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoList(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();

  Future<void> _createTodoList() async {
    final name = _listNameController.text.trim();
    if (name.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('lists').add({
      'name': name,
      'members': [widget.user.uid],
    });
    final container = ProviderScope.containerOf(context);
    container.read(listIdProvider.notifier).state = doc.id;
    _listNameController.clear();
  }

  // 8桁英数字のワンタイム招待コードを生成しFirestoreに保存
  Future<void> _generateInviteCode() async {
    final container = ProviderScope.containerOf(context);
    final selectedListId = container.read(listIdProvider);
    debugPrint('[_generateInviteCode] called. selectedListId=$selectedListId');
    if (selectedListId == null) {
      if (context.mounted) {
        debugPrint('[_generateInviteCode] リスト未選択。SnackBar表示');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リストを選択してください')),
        );
      }
      return;
    }
    final code = _randomCode(8);
    debugPrint('[_generateInviteCode] 生成した招待コード: $code');
    await FirebaseFirestore.instance.collection('invites').doc(code).set({
      'listId': selectedListId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => InviteCodeIssuedDialog(code: code),
      );
    }
  }

  // 8桁英数字生成
  String _randomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // 招待コードで参加（ワンタイム）
  Future<void> _joinListByInviteCode(String code) async {
    final doc = await FirebaseFirestore.instance.collection('invites').doc(code).get();
    if (doc.exists) {
      final listId = doc['listId'] as String?;
      if (listId != null) {
        // リストに参加
        await FirebaseFirestore.instance.collection('lists').doc(listId).update({
          'members': FieldValue.arrayUnion([widget.user.uid]),
        });
        // ワンタイムなので招待コードを削除
        await doc.reference.delete();
        final container = ProviderScope.containerOf(context);
        container.read(listIdProvider.notifier).state = listId;
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無効な招待コードです')),
        );
      }
    }
  }

  Future<void> _joinListByCode(String code) async {
    final doc = await FirebaseFirestore.instance.collection('lists').doc(code).get();
    if (doc.exists) {
      await doc.reference.update({
        'members': FieldValue.arrayUnion([widget.user.uid]),
      });
      final container = ProviderScope.containerOf(context);
      container.read(listIdProvider.notifier).state = code;
    }
  }

  Future<void> _addTodo() async {
    final container = ProviderScope.containerOf(context);
    final selectedListId = container.read(listIdProvider);
    final text = _controller.text.trim();
    if (text.isNotEmpty && selectedListId != null) {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(selectedListId)
          .collection('todos')
          .add({'title': text, 'isDone': false});
      _controller.clear();
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    final container = ProviderScope.containerOf(context);
    final selectedListId = container.read(listIdProvider);
    if (selectedListId == null) return;
    await FirebaseFirestore.instance
        .collection('lists')
        .doc(selectedListId)
        .collection('todos')
        .doc(todo.id)
        .update({'isDone': !todo.isDone});
  }

  Future<void> _removeTodo(Todo todo) async {
    final container = ProviderScope.containerOf(context);
    final selectedListId = container.read(listIdProvider);
    if (selectedListId == null) return;
    await FirebaseFirestore.instance
        .collection('lists')
        .doc(selectedListId)
        .collection('todos')
        .doc(todo.id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lists')
          .where('members', arrayContains: widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final lists = snapshot.hasData
            ? snapshot.data!.docs.map((doc) => TodoList.fromDoc(doc)).toList()
            : <TodoList>[];
        final listIds = lists.map((l) => l.id).toList();
        final container = ProviderScope.containerOf(context);
        final selectedListId = container.read(listIdProvider);
        String? selectedListName;
        if (selectedListId != null) {
          final selectedList = lists.firstWhere(
            (l) => l.id == selectedListId,
            orElse: () => lists.isNotEmpty ? lists.first : TodoList(id: '', name: '', members: []),
          );
          if (selectedList.id.isNotEmpty) {
            selectedListName = selectedList.name;
          }
        }
        // リスト未選択時の自動選択
        if ((selectedListId == null || !listIds.contains(selectedListId)) && lists.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            container.read(listIdProvider.notifier).state = lists.first.id;
          });
        }
        return Scaffold(
          drawer: SideMenu(
            user: widget.user,
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
            },
            onInviteJoin: () {
              showDialog(
                context: context,
                builder: (context) => Consumer(
                  builder: (context, ref, _) => InviteCodeDialog(
                    onJoin: (code) async {
                      final inviteVM = ref.read(inviteViewModelProvider.notifier);
                      final listId = await inviteVM.joinByInviteCode(code);
                      if (listId != null) {
                        // 必要に応じてリスト選択状態をViewModelで管理
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('無効な招待コードです')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
          appBar: AppBar(
            title: Consumer(
              builder: (context, ref, _) {
                final listId = ref.watch(listIdProvider);
                final lists = snapshot.hasData
                    ? snapshot.data!.docs.map((doc) => TodoList.fromDoc(doc)).toList()
                    : <TodoList>[];
                String? selectedListName;
                if (listId != null) {
                  final selectedList = lists.firstWhere(
                    (l) => l.id == listId,
                    orElse: () => lists.isNotEmpty ? lists.first : TodoList(id: '', name: '', members: []),
                  );
                  if (selectedList.id.isNotEmpty) {
                    selectedListName = selectedList.name;
                  }
                }
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.95,
                        child: TodoListSelectorSheet(
                          selectedListId: selectedListId,
                          onSelected: (list) {
                            final container = ProviderScope.containerOf(context);
                            container.read(listIdProvider.notifier).state = list.id;
                          },
                          onSettings: (list) {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TodoListSettingsPage(list: list),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedListName ?? 'ToDo List',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    ],
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '新しいリストを作成',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Consumer(
                      builder: (context, ref, _) {
                        final listVM = ref.read(todoListViewModelProvider.notifier);
                        return AlertDialog(
                          title: const Text('新しいリストを作成'),
                          content: TextField(
                            controller: _listNameController,
                            decoration: const InputDecoration(hintText: 'リスト名'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context); // 先にダイアログを閉じる
                                final id = await listVM.createList(_listNameController.text.trim());
                                _listNameController.clear();
                                if (id != null) {
                                  final container = ProviderScope.containerOf(context);
                                  container.read(listIdProvider.notifier).state = id;
                                }
                              },
                              child: const Text('作成'),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final listId = ref.watch(listIdProvider);
                  final isListSelected = listId != null && listId.isNotEmpty;
                  return IconButton(
                    icon: const Icon(Icons.link),
                    tooltip: '招待コードを発行',
                    onPressed: isListSelected
                        ? () async {
                            final inviteVM = ref.read(inviteViewModelProvider.notifier);
                            final code = await inviteVM.generateInviteCode(listId!);
                            if (context.mounted && code != null) {
                              showDialog(
                                context: context,
                                builder: (context) => InviteCodeIssuedDialog(code: code),
                              );
                            }
                          }
                        : null,
                  );
                },
              ),
            ],
          ),
          body: TodoListView(),
        );
      },
    );
  }
}

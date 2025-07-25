import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/model/todo_list.dart';
import 'package:todo/model/todo.dart';
import 'package:todo/repository/todo_list_repository.dart';

import 'firebase_options.dart';
import 'package:todo/view/page/invite_code_dialog.dart';
import 'package:todo/view/page/invite_code_issued_dialog.dart';
import 'package:todo/view/page/side_menu.dart';
import 'package:todo/view/page/todo_list_selector.dart';
import 'package:todo/view/page/todo_list_settings_page.dart';
import 'package:todo/view/page/todo_list_view.dart';
import 'package:todo/view_model/todo_list_view_model.dart';
import 'package:todo/view_model/todo_view_model.dart';
import 'package:todo/view_model/invite_view_model.dart';


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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
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

  Future<void> _signInAnonymously(BuildContext context) async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final user = cred.user;
      if (user != null) {
        // Firestoreのnicknameに「未登録」を保存
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': '未登録',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MyHomePage(user: user)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('匿名ログインに失敗:  $e')),
        );
      }
    }
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.person_outline, color: Colors.blueGrey),
              label: const Text('ログインせずに使う'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[50],
                foregroundColor: Colors.black87,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              onPressed: () => _signInAnonymously(context),
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

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _listNameController = TextEditingController();

  // クラス内に追加
  Future<void> _createDefaultTodoListIfNeededOnce(ProviderContainer container) async {
    final repository = TodoListRepository(firestore: FirebaseFirestore.instance);
    final user = widget.user;
    // 既に「ToDo List」が存在するかチェック
    final snapshot = await FirebaseFirestore.instance
        .collection('lists')
        .where('members', arrayContains: user.uid)
        .where('name', isEqualTo: 'ToDo List')
        .get();
    if (snapshot.docs.isEmpty) {
      final newListId = await repository.createList('ToDo List', user.uid);
      container.read(listIdProvider.notifier).state = newListId;
    } else {
      // 既存のToDo Listを選択状態に
      container.read(listIdProvider.notifier).state = snapshot.docs.first.id;
    }
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
        // リストが1つもない場合は自動作成
        if (lists.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createDefaultTodoListIfNeededOnce(container);
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
                      const Icon(Icons.arrow_drop_down, color: Colors.orangeAccent),
                    ],
                  ),
                );
              },
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final listId = ref.watch(listIdProvider);
                  final isListSelected = listId != null && listId.isNotEmpty;
                  return IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'リスト設定',
                    onPressed: isListSelected
                        ? () {
                            final lists = snapshot.hasData
                                ? snapshot.data!.docs.map((doc) => TodoList.fromDoc(doc)).toList()
                                : <TodoList>[];
                            final selected = lists.firstWhere(
                              (l) => l.id == listId,
                              orElse: () => lists.isNotEmpty ? lists.first : TodoList(id: '', name: '', members: []),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TodoListSettingsPage(list: selected),
                              ),
                            );
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

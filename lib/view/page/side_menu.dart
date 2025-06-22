import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/view/page/profile_edit_page.dart';

class SideMenu extends ConsumerWidget {
  final User user;
  final VoidCallback onLogout;
  final VoidCallback onInviteJoin;
  const SideMenu({super.key, required this.user, required this.onLogout, required this.onInviteJoin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ユーザー情報やログアウトはViewModel経由にリファクタ可能
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              final nickname = snapshot.data?.data()?['nickname'] ?? '未登録';
              return UserAccountsDrawerHeader(
                accountName: Text(nickname),
                accountEmail: Text(user.email ?? ''),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.input),
            title: const Text('招待コードで参加'),
            onTap: () {
              Navigator.pop(context);
              onInviteJoin();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('プロフィール編集'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          UserAccountsDrawerHeader(
            accountName: Text(user.displayName ?? 'No Name'),
            accountEmail: Text(user.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(
                (user.displayName != null && user.displayName!.isNotEmpty)
                    ? user.displayName![0]
                    : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.input),
            title: const Text('招待コードで参加'),
            onTap: () {
              Navigator.pop(context);
              onInviteJoin();
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

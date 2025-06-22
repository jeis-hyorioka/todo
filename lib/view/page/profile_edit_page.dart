import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/view_model/user_profile_view_model.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラー: $e')),
        data: (profile) {
          _controller.text = profile?.nickname ?? '';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ニックネーム', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'ニックネームを入力'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() => _loading = true);
                            await ref.read(userProfileViewModelProvider.notifier).updateNickname(_controller.text.trim());
                            setState(() => _loading = false);
                            if (mounted) Navigator.pop(context);
                          },
                    child: _loading ? const CircularProgressIndicator() : const Text('保存'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

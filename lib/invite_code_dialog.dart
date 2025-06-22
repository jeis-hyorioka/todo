import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteCodeDialog extends ConsumerWidget {
  final Future<void> Function(String code) onJoin;
  const InviteCodeDialog({super.key, required this.onJoin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String inputCode = '';
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('招待コードで参加'),
        content: TextField(
          decoration: const InputDecoration(hintText: '8桁の招待コードを入力'),
          maxLength: 8,
          onChanged: (value) {
            setState(() {
              inputCode = value.trim().toUpperCase();
            });
          },
          onSubmitted: (value) async {
            if (inputCode.isNotEmpty) {
              await onJoin(inputCode);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: inputCode.isNotEmpty
                ? () async {
                    await onJoin(inputCode);
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('参加'),
          ),
        ],
      ),
    );
  }
}

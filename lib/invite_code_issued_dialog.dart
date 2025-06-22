import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteCodeIssuedDialog extends ConsumerWidget {
  final String code;
  const InviteCodeIssuedDialog({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.link, color: Colors.teal, size: 28),
          const SizedBox(width: 8),
          Text('招待コードを発行', style: GoogleFonts.notoSansJp(fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              code,
              style: GoogleFonts.notoSansJp(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: Colors.teal[800],
              ),
              toolbarOptions: const ToolbarOptions(copy: true),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.teal, size: 24),
              tooltip: 'コピー',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('招待コードをコピーしました')),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

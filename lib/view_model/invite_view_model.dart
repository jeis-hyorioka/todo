import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo/main.dart';
import '../repository/invite_repository.dart';

final inviteViewModelProvider = StateNotifierProvider.autoDispose<InviteViewModel, AsyncValue<String?>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final userId = ref.watch(userIdProvider);
  final repo = InviteRepository(firestore: firestore);
  final notifier = InviteViewModel(repo, userId ?? '');
  ref.keepAlive(); // 追加: disposeされないようにする
  return notifier;
});

class InviteViewModel extends StateNotifier<AsyncValue<String?>> {
  final InviteRepository repository;
  final String userId;
  InviteViewModel(this.repository, this.userId) : super(const AsyncValue.data(null));

  Future<String?> generateInviteCode(String listId) async {
    try {
      final code = await repository.generateInviteCode(listId);
      state = AsyncValue.data(code);
      return code;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<String?> joinByInviteCode(String code) async {
    try {
      final listId = await repository.joinByInviteCode(code, userId);
      return listId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo/model/user_profile.dart';
import 'package:todo/repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userProfileViewModelProvider = StateNotifierProvider<UserProfileViewModel, AsyncValue<UserProfile?>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final repository = UserRepository(firestore: firestore);
  return UserProfileViewModel(repository, user?.uid);
});

class UserProfileViewModel extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserRepository repository;
  final String? uid;

  UserProfileViewModel(this.repository, this.uid) : super(const AsyncValue.loading()) {
    if (uid != null) _fetch();
    else state = const AsyncValue.data(null);
  }

  Future<void> _fetch() async {
    try {
      final profile = await repository.fetchProfile(uid!);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateNickname(String nickname) async {
    if (uid == null) return;
    try {
      await repository.updateNickname(uid!, nickname);
      await _fetch();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class UserProfile {
  final String uid;
  final String nickname;

  UserProfile({required this.uid, required this.nickname});

  factory UserProfile.fromMap(String uid, Map<String, dynamic>? map) {
    return UserProfile(
      uid: uid,
      nickname: map?['nickname'] ?? '未登録',
    );
  }

  Map<String, dynamic> toMap() => {
    'nickname': nickname,
  };
}

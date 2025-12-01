class User {
  final String userId; // DB의 고유 ID (_id)
  final String id; // 로그인 ID
  final String nickname;

  User({required this.userId, required this.id, required this.nickname});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      id: json['id'],
      nickname: json['nickname'],
    );
  }
}

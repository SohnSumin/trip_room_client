class Member {
  final String userId;
  final String nickname;

  Member({required this.userId, required this.nickname});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(userId: json['_id'], nickname: json['nickname']);
  }
}

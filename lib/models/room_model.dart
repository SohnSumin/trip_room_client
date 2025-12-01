class Room {
  final String id;
  final String title;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final String creatorId;
  final String? imageId;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.title,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.creatorId,
    this.imageId,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'],
      title: json['title'],
      country: json['country'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      creatorId: json['creatorId'],
      imageId: json['imageId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'country': country,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'creatorId': creatorId,
      'imageId': imageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class RoomDetail extends Room {
  final List<String> members;

  RoomDetail({
    required super.id,
    required super.title,
    required super.country,
    required super.startDate,
    required super.endDate,
    required super.creatorId,
    required super.createdAt,
    super.imageId,
    required this.members,
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    return RoomDetail(
      id: json['_id'],
      title: json['title'],
      country: json['country'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      creatorId: json['creatorId'],
      imageId: json['imageId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      members: List<String>.from(json['members'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['members'] = members;
    return json;
  }
}

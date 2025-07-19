// lib/models/community.dart

class Community {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorUsername;
  final String? creatorAvatarUrl;
  final DateTime createdAt;
  final int memberCount;
  final bool isPrivate;
  final String? imageUrl;
  final List<String> tags;
  final bool isJoined;
  final String? sport; // Optional sport association (NFL, NBA, MLB, etc.)

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorAvatarUrl,
    required this.createdAt,
    this.memberCount = 1,
    this.isPrivate = false,
    this.imageUrl,
    this.tags = const [],
    this.isJoined = false,
    this.sport,
  });

  // Create a copy with modified properties
  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    String? creatorUsername,
    String? creatorAvatarUrl,
    DateTime? createdAt,
    int? memberCount,
    bool? isPrivate,
    String? imageUrl,
    List<String>? tags,
    bool? isJoined,
    String? sport,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      isPrivate: isPrivate ?? this.isPrivate,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isJoined: isJoined ?? this.isJoined,
      sport: sport ?? this.sport,
    );
  }

  // Create Community from JSON/Map (for Supabase)
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creator_id'] ?? '',
      creatorUsername: json['creator_username'] ?? '',
      creatorAvatarUrl: json['creator_avatar_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      memberCount: json['member_count'] ?? 1,
      isPrivate: json['is_private'] ?? false,
      imageUrl: json['image_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      isJoined: json['is_joined'] ?? false,
      sport: json['sport'],
    );
  }

  // Convert Community to JSON/Map (for Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'creator_username': creatorUsername,
      'creator_avatar_url': creatorAvatarUrl,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
      'is_private': isPrivate,
      'image_url': imageUrl,
      'tags': tags,
      'sport': sport,
    };
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 
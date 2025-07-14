class Sportsbook {
  final String id;
  final String name;
  final bool isEnabled;
  final String? logoUrl;

  Sportsbook({
    required this.id,
    required this.name,
    required this.isEnabled,
    this.logoUrl,
  });

  factory Sportsbook.fromJson(Map<String, dynamic> json) {
    return Sportsbook(
      id: json['id'],
      name: json['name'],
      isEnabled: json['is_enabled'] ?? true,
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_enabled': isEnabled,
      'logo_url': logoUrl,
    };
  }
}

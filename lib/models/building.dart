class Building {
  final String id;
  final String userId;
  final String name;
  final String type;
  final int level;
  final int coinsToNextLevel;
  final String description;

  const Building({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.level = 1,
    this.coinsToNextLevel = 100,
    this.description = '',
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      level: json['level'] as int? ?? 1,
      coinsToNextLevel: json['coinsToNextLevel'] as int? ?? 100,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type,
      'level': level,
      'coinsToNextLevel': coinsToNextLevel,
      'description': description,
    };
  }

  Building copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    int? level,
    int? coinsToNextLevel,
    String? description,
  }) {
    return Building(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
      coinsToNextLevel: coinsToNextLevel ?? this.coinsToNextLevel,
      description: description ?? this.description,
    );
  }
}

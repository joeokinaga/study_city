class Reward {
  final int exp;
  final int coins;

  const Reward({
    required this.exp,
    required this.coins,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      exp: json['exp'] as int,
      coins: json['coins'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exp': exp,
      'coins': coins,
    };
  }
}

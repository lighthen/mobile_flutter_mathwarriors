class User {
  final int id;
  final String username;
  final String tier;
  final int points;

  User({
    required this.id,
    required this.username,
    required this.tier,
    required this.points,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      tier: json['tier'] as String,
      points: json['points'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'tier': tier,
    'points': points,
  };
}

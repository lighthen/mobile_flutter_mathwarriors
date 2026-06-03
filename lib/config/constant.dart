class AppConstants {
  static const String appName = "MathWarriors";
  
  // Rank Tiers
  static const List<Map<String, dynamic>> rankTiers = [
    {'name': 'Pemula', 'minPoints': 0, 'icon': '🌱'},
    {'name': 'Menengah', 'minPoints': 100, 'icon': '🌿'},
    {'name': 'Ahli', 'minPoints': 300, 'icon': '🌳'},
    {'name': 'Master', 'minPoints': 600, 'icon': '🦅'},
    {'name': 'Grandmaster', 'minPoints': 1000, 'icon': '⚡'},
    {'name': 'Legend', 'minPoints': 1500, 'icon': '👑'},
  ];
  
  // Scoring
  static const int pointCorrect = 3;
  static const int pointWrong = -2;
  static const int initialTime = 60;
}
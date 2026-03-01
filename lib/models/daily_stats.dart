class DailyStats {
  final String date;
  final int totalDuration; // seconds
  final int sessionCount;
  final int reviewCount;

  const DailyStats({
    required this.date,
    this.totalDuration = 0,
    this.sessionCount = 0,
    this.reviewCount = 0,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: json['date'] as String,
      totalDuration: json['totalDuration'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalDuration': totalDuration,
      'sessionCount': sessionCount,
      'reviewCount': reviewCount,
    };
  }
}

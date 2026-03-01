class ReviewSchedule {
  final int interval;
  final double easeFactor;
  final DateTime nextReviewDate;

  const ReviewSchedule({
    required this.interval,
    required this.easeFactor,
    required this.nextReviewDate,
  });
}

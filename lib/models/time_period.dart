enum TimePeriod {
  week(label: 'Week', days: 7),
  month(label: 'Month', days: 30),
  year(label: 'Year', days: 365),
  allTime(label: 'All Time', days: -1);

  final String label;
  final int days;

  const TimePeriod({required this.label, required this.days});
}

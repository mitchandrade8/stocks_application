// lib/models/time_series_datapoint.dart
class TimeSeriesDataPoint {
  final DateTime date;
  final double closePrice;

  TimeSeriesDataPoint({required this.date, required this.closePrice});
}

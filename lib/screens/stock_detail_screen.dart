// lib/screens/stock_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/stock_api_service.dart';
import '../models/time_series_datapoint.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final String companyName;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.companyName,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final StockApiService _apiService =
      StockApiService(); // Needs StockApiService to be imported
  Future<List<TimeSeriesDataPoint>>?
      _timeSeriesFuture; // Needs TimeSeriesDataPoint to be imported

  @override
  void initState() {
    super.initState();
    _fetchTimeSeriesData();
  }

  void _fetchTimeSeriesData() {
    setState(() {
      // This now calls the method from the imported _apiService instance
      _timeSeriesFuture = _apiService.fetchDailyTimeSeries(widget.symbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.companyName, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price History (Last ~100 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<TimeSeriesDataPoint>>(
                // Needs TimeSeriesDataPoint
                future: _timeSeriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error fetching price history: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final seriesData = snapshot
                        .data!; // seriesData is List<TimeSeriesDataPoint>
                    return LineChart(
                      _buildLineChartData(seriesData,
                          context), // Pass List<TimeSeriesDataPoint>
                      duration: const Duration(milliseconds: 250),
                    );
                  } else {
                    return const Center(
                        child: Text('No time series data available.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(
      List<TimeSeriesDataPoint> seriesData, BuildContext context) {
    // Needs TimeSeriesDataPoint
    List<FlSpot> spots = [];
    for (int i = 0; i < seriesData.length; i++) {
      spots.add(FlSpot(i.toDouble(), seriesData[i].closePrice));
    }

    double minY = double.maxFinite;
    double maxY = double.minPositive;
    if (seriesData.isNotEmpty) {
      for (var point in seriesData) {
        if (point.closePrice < minY) minY = point.closePrice;
        if (point.closePrice > maxY) maxY = point.closePrice;
      }
      minY = minY * 0.95;
      maxY = maxY * 1.05;
      if (minY == maxY) {
        minY = minY - 1;
        maxY = maxY + 1;
      }
    } else {
      minY = 0;
      maxY = 100;
    }

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.grey, strokeWidth: 0.4);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Colors.grey, strokeWidth: 0.4);
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: leftTitleWidgets)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int dataLength = seriesData
                      .length; // seriesData is List<TimeSeriesDataPoint>
                  if (dataLength == 0) return const SizedBox.shrink();
                  int labelInterval = (dataLength / 5).ceil();
                  if (labelInterval == 0) labelInterval = 1;
                  if (value.toInt() % labelInterval == 0 &&
                      value.toInt() < dataLength) {
                    final date = seriesData[value.toInt()]
                        .date; // Accessing .date from TimeSeriesDataPoint
                    return SideTitleWidget(
                        meta: meta,
                        space: 8.0,
                        child: Text('${date.month}/${date.day}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54)));
                  }
                  return const SizedBox.shrink();
                })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: Colors.grey, width: 1)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black54,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    if (value == meta.min || value == meta.max) {
      text = value.toStringAsFixed(0);
    } else if (meta.appliedInterval < 20 &&
        (value % (meta.appliedInterval * 2) == 0) &&
        value != meta.min &&
        value != meta.max) {
      text = value.toStringAsFixed(0);
    } else if (meta.appliedInterval >= 20 &&
        (value % meta.appliedInterval == 0) &&
        value != meta.min &&
        value != meta.max) {
      text = value.toStringAsFixed(0);
    } else {
      return Container();
    }

    return SideTitleWidget(
      meta: meta,
      space: 6.0,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}

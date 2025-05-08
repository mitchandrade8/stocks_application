// lib/screens/stock_detail_screen.dart
import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// We no longer need the API service or TimeSeriesDataPoint model directly in the build flow here
// (though _buildLineChartData still uses TimeSeriesDataPoint conceptually)
import '../models/time_series_datapoint.dart'; // Keep this for the _buildLineChartData signature

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
  // No need for API service instance or Future here anymore

  late List<TimeSeriesDataPoint> _placeholderData; // Store the generated data

  @override
  void initState() {
    super.initState();
    // Generate the placeholder data when the widget is initialized
    _placeholderData = _generatePlaceholderData();
  }

  // --- Method to Generate Sample Data ---
  List<TimeSeriesDataPoint> _generatePlaceholderData() {
    List<TimeSeriesDataPoint> data = [];
    DateTime today = DateTime.now();
    // Start price based roughly on symbol (just for variety)
    double currentPrice = widget.symbol == 'AAPL'
        ? 170
        : widget.symbol == 'META'
            ? 300
            : widget.symbol == 'AMZN'
                ? 130
                : widget.symbol == 'NFLX'
                    ? 400
                    : widget.symbol == 'GOOGL'
                        ? 135
                        : 150.0;

    final random = Random();

    for (int i = 0; i < 100; i++) {
      // Simulate 100 days ending today
      final date = today.subtract(Duration(days: 99 - i));
      // Simulate some price movement (random walk with slight upward bias)
      double change = (random.nextDouble() * 4.0) - 1.8 + 0.1; // -1.8 to +2.2
      currentPrice += change;
      if (currentPrice <= 5) {
        // Ensure price doesn't go unrealistically low
        currentPrice = 5 + random.nextDouble() * 2;
      }
      data.add(TimeSeriesDataPoint(date: date, closePrice: currentPrice));
    }
    return data;
  }
  // --- End of Sample Data Generation ---

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
              'Price History (Sample Data)', // Update title
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              // Chart container
              child: _placeholderData.isEmpty
                  ? const Center(
                      child: Text(
                          'No data generated.')) // Should not happen with generator
                  : LineChart(
                      // Build chart directly with placeholder data
                      _buildLineChartData(_placeholderData, context),
                      duration: const Duration(milliseconds: 250),
                    ),
            ),
            // You can still add other static details here if needed
            const SizedBox(height: 20),
            Text(
              "Note: Displaying generated sample data.",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- Chart Building Logic (using fl_chart) ---
  // This method remains largely the same, taking the list of data points
  LineChartData _buildLineChartData(
      List<TimeSeriesDataPoint> seriesData, BuildContext context) {
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
      double padding = (maxY - minY) * 0.10; // Increased padding to 10%
      // Ensure padding doesn't make minY negative if all prices are positive
      minY = (minY - padding <= 0) ? 0 : (minY - padding);
      maxY += padding;
      if (minY >= maxY) {
        // Check if minY is still too close or equal to maxY
        minY = (minY > 1) ? minY - 1 : 0; // Adjust down, but not below 0
        maxY += 1; // Adjust up
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
        horizontalInterval:
            (maxY - minY) / 4, // Example: auto interval for horizontal lines
        verticalInterval: (seriesData.length / 5)
            .toDouble(), // Example: auto interval for vertical lines
        getDrawingHorizontalLine: (value) => const FlLine(
            color: Colors.grey,
            strokeWidth: 0.4,
            dashArray: [3, 3]), // Dashed lines
        getDrawingVerticalLine: (value) => const FlLine(
            color: Colors.transparent), // Hide vertical grid lines if desired
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: (maxY - minY) / 4,
                getTitlesWidget: leftTitleWidgets)),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (seriesData.length / 5).ceil().toDouble(),
                getTitlesWidget: (value, meta) {
                  int dataLength = seriesData.length;
                  if (dataLength == 0) return const SizedBox.shrink();
                  int index = value.toInt();
                  // Show label only at calculated intervals, preventing index out of bounds
                  if (index >= 0 &&
                      index < dataLength &&
                      index % (dataLength / 5).ceil() == 0) {
                    final date = seriesData[index].date;
                    return SideTitleWidget(
                        meta: meta,
                        space: 8.0,
                        child: Text('${date.month}/${date.day}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold)));
                  }
                  return const SizedBox.shrink();
                })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false), // Hide the outer chart border
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          // Use gradient for the line color
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3, // Slightly thicker line
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            // Use gradient below the line too
            show: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context)
                    .colorScheme
                    .secondary
                    .withOpacity(0.0), // Fade to transparent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        // Customize touch interactions
        touchTooltipData: LineTouchTooltipData(
          //tooltipBgColor: Colors.blueGrey.withOpacity(0.8), // <<< REMOVED THIS LINE
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots
                .map((barSpot) {
                  final flSpot = barSpot;
                  // Prevent index out of bounds error if spotIndex is invalid
                  if (flSpot.spotIndex < 0 ||
                      flSpot.spotIndex >= seriesData.length) {
                    return null;
                  }
                  final pointData = seriesData[flSpot.spotIndex];
                  return LineTooltipItem(
                    '${pointData.date.month}/${pointData.date.day}/${pointData.date.year}\n',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    children: [
                      TextSpan(
                        text: '\$${pointData.closePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    textAlign: TextAlign
                        .left, // Changed alignment for potentially better fit
                  );
                })
                .where((item) => item != null)
                .toList(); // Ensure null items are filtered out
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          // Customize touch indicator
          return spotIndexes
              .map((index) {
                // Ensure index is valid for seriesData before accessing it (optional safety)
                if (index < 0 || index >= seriesData.length) return null;

                return TouchedSpotIndicatorData(
                  const FlLine(
                      color: Colors.redAccent,
                      strokeWidth: 2), // Changed color slightly
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor:
                                Colors.redAccent), // Slightly larger dot
                  ),
                );
              })
              .where((item) => item != null)
              .toList(); // Filter out potential nulls
        },
      ),
    );
  }

  // Helper function for Y-axis (left) titles
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.black54,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text = value.toStringAsFixed(0); // Simple formatting for price axis

    // Only show titles at calculated intervals provided by 'meta'
    if (value != meta.min &&
        value != meta.max &&
        value % meta.appliedInterval != 0) {
      // This logic might need refinement based on fl_chart version and desired label density
      // return Container(); // Uncomment to show fewer labels
    }

    return SideTitleWidget(
      meta: meta,
      space: 6.0,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
} // End of _StockDetailScreenState class

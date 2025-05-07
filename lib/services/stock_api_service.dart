// lib/services/stock_api_service.dart
import 'dart:convert'; // For json.decode
import 'package:http/http.dart' as http; // For making HTTP requests

// Relative imports to other files in your project
import '../models/stock_data.dart'; // Defines the StockData class
import '../models/time_series_datapoint.dart'; // Defines the TimeSeriesDataPoint class
import '../config/api_constants.dart'; // Defines your alphaVantageApiKey

class StockApiService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  /// Fetches the current global quote for a given stock symbol.
  Future<StockData> fetchStockQuote(String symbol, String companyName) async {
    // Construct the API URL for GLOBAL_QUOTE
    final String apiUrl =
        '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageApiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        final Map<String, dynamic> data = json.decode(response.body);

        // Check for API notes (e.g., rate limit) or if the 'Global Quote' key is missing/empty
        if (data.containsKey('Note')) {
          print('API Note for $symbol (Quote): ${data["Note"]}');
          throw Exception(
              'API limit likely reached or other issue: ${data["Note"]}');
        }
        if (data['Global Quote'] == null ||
            (data['Global Quote'] as Map).isEmpty) {
          print(
              'API Response for $symbol (Quote) - Missing Global Quote: $data');
          throw Exception(
              'Failed to load stock quote for $symbol: "Global Quote" data is missing or empty.');
        }

        // Pass the companyName manually as Alpha Vantage GLOBAL_QUOTE doesn't include it
        return StockData.fromJson(data, companyName);
      } else {
        // If the server did not return a 200 OK response,
        // throw an exception with the status code.
        print(
            'Failed to load stock quote for $symbol. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load stock quote for $symbol. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Catch any other errors during the process (network issues, parsing errors)
      print('Error fetching stock quote for $symbol: $e');
      // Re-throw the exception to be handled by the caller
      throw Exception('Error fetching stock quote for $symbol: $e');
    }
  }

  /// Fetches the daily adjusted time series data for a given stock symbol.
  /// Returns a list of the most recent ~100 data points, sorted chronologically.
  Future<List<TimeSeriesDataPoint>> fetchDailyTimeSeries(String symbol) async {
    // Construct the API URL for TIME_SERIES_DAILY_ADJUSTED
    final String apiUrl =
        '$_baseUrl?function=TIME_SERIES_DAILY_ADJUSTED&symbol=$symbol&apikey=$alphaVantageApiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check for API notes (e.g., rate limit) or API error messages
        if (data.containsKey('Note')) {
          print('API Note for $symbol (Time Series): ${data["Note"]}');
          throw Exception(
              'API rate limit likely reached for $symbol time series: ${data["Note"]}');
        }
        if (data.containsKey('Error Message')) {
          print(
              'API Error for $symbol (Time Series): ${data["Error Message"]}');
          throw Exception(
              'API error for $symbol time series: ${data["Error Message"]}');
        }

        // Access the 'Time Series (Daily)' part of the JSON
        final Map<String, dynamic>? timeSeriesJson =
            data['Time Series (Daily)'];
        if (timeSeriesJson == null || timeSeriesJson.isEmpty) {
          print(
              'API Response for $symbol (Time Series) - Missing Time Series Data: $data');
          throw Exception(
              'Time Series (Daily) data not found or empty for $symbol.');
        }

        List<TimeSeriesDataPoint> seriesData = [];
        // Get all dates, sort them chronologically (oldest to newest)
        final sortedDates = timeSeriesJson.keys.toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

        // Take the last 100 data points, or all if less than 100
        final recentDates = sortedDates.length > 100
            ? sortedDates.sublist(sortedDates.length - 100)
            : sortedDates;

        for (var dateStr in recentDates) {
          final dayData = timeSeriesJson[dateStr] as Map<String, dynamic>;
          // Ensure '4. close' exists and is a string before parsing
          if (dayData['4. close'] != null && dayData['4. close'] is String) {
            seriesData.add(TimeSeriesDataPoint(
              date: DateTime.parse(dateStr),
              closePrice: double.parse(dayData['4. close'] as String),
            ));
          } else {
            print(
                'Warning: Missing or invalid "4. close" data for $symbol on $dateStr');
            // Optionally skip this data point or handle as an error
          }
        }

        // The seriesData is now in chronological order (oldest to most recent from the 'recentDates' slice)
        return seriesData;
      } else {
        print(
            'Failed to load time series for $symbol. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load time series for $symbol. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching time series for $symbol: $e');
      throw Exception('Error fetching time series for $symbol: $e');
    }
  }
}

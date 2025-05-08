// lib/services/stock_api_service.dart
import 'dart:convert'; // For json.decode
import 'package:http/http.dart' as http; // For making HTTP requests

// Import the yahoo finance package - This should define YahooFinanceService and TickData
import 'package:yahoo_finance_data_reader/yahoo_finance_data_reader.dart';

// Relative imports to other files in your project (Verify these paths match your structure)
import '../models/stock_data.dart'; // Defines the StockData class (for quotes)
import '../models/time_series_datapoint.dart'; // Defines the TimeSeriesDataPoint class (for charts)
import '../config/api_constants.dart'; // Defines your API keys (for fetchStockQuote)

class StockApiService {
  // Base URL for Alpha Vantage (if still using for quotes)
  static const String _alphaVantageBaseUrl =
      'https://www.alphavantage.co/query';

  /// Fetches the current global quote for a given stock symbol using Alpha Vantage.
  Future<StockData> fetchStockQuote(String symbol, String companyName) async {
    // Ensure API key is available (optional check)
    // Note: Ensure alphaVantageApiKey is defined in your api_constants.dart
    if (alphaVantageApiKey == 'QVUN4IUTD2UOC9PW' ||
        alphaVantageApiKey.isEmpty) {
      print('Warning: Alpha Vantage API Key seems to be a placeholder.');
      // Consider throwing an error if the key is essential for this part too
      // throw Exception('Alpha Vantage API Key not set in api_constants.dart');
    }

    final String apiUrl =
        '$_alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageApiKey';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('Note') ||
            data['Global Quote'] == null ||
            (data['Global Quote'] as Map).isEmpty) {
          print('API Response for $symbol (Quote): $data');
          throw Exception(
              'Failed to load stock quote for $symbol or API rate limit reached. Response: ${data.containsKey("Note") ? data["Note"] : "Empty quote data."}');
        }
        return StockData.fromJson(data, companyName);
      } else {
        print(
            'Failed to load stock quote for $symbol. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load stock quote for $symbol. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock quote for $symbol: $e');
      throw Exception('Error fetching stock quote for $symbol: $e');
    }
  }

  /// Fetches historical daily data using the YahooFinanceService from the package.
  /// Assumes getTickerData returns List<TickData> and TickData has .date and .adjClose
  Future<List<TimeSeriesDataPoint>> fetchYahooHistory(String symbol) async {
    print(
        "Attempting to fetch Yahoo Finance history for: $symbol using YahooFinanceService");
    // Instantiate the service from the package
    final financeService = YahooFinanceService();

    try {
      // Call getTickerData - Assuming this returns List<TickData> based on package examples/structure.
      // If you get 'TickData' undefined error here, the class name provided by the package is different.
      // Use IDE hover/autocomplete on getTickerData or the result to verify.
      final tickerDataList = await financeService.getTickerData(symbol);

      // Use the variable name 'tickerDataList' consistently below
      if (tickerDataList.isEmpty) {
        print('Yahoo Finance returned empty data list for $symbol');
        return []; // Return empty list if no data
      }

      List<TimeSeriesDataPoint> seriesData = [];
      // Iterate through the TickData objects
      // Use the variable name 'tickerDataList' consistently here
      for (var tick in tickerDataList) {
        // Use the variable name 'tick' consistently below
        // If you get errors that '.date' or '.adjClose' don't exist here,
        // it means the TickData class from the package uses different property names.
        // Use IDE autocomplete on 'tick.' to find the correct names.
        try {
          final DateTime date = tick.date;
          final double adjClose = tick.adjClose;

          // Basic validation - skip potential bad data points
          if (adjClose.isFinite && !adjClose.isNaN) {
            seriesData.add(TimeSeriesDataPoint(
              date: date,
              closePrice: adjClose, // Use adjusted close for charting
            ));
          } else {
            print(
                "Skipping tick data point with invalid adjClose: $tick for symbol $symbol");
          }
        } catch (e) {
          // Log if accessing properties on 'tick' fails
          print(
              "Error processing tick data point. Type: ${tick.runtimeType}, Content: $tick for symbol $symbol. Error: $e");
          // Optionally continue to next tick or rethrow, depending on desired behavior
          // continue;
        }
      }

      // Sorting might be optional if data is already sorted (Yahoo usually is chronological)
      seriesData.sort((a, b) => a.date.compareTo(b.date));

      // Limit to recent data if desired (or handle date range in the API call)
      // Taking the last 100 points after sorting
      final recentData = seriesData.length > 100
          ? seriesData.sublist(seriesData.length - 100)
          : seriesData;

      print(
          "Successfully processed ${recentData.length} data points from Yahoo Finance for $symbol");
      return recentData;
    } catch (e) {
      // Catch errors from the financeService.getTickerData call itself
      print(
          'Error fetching Yahoo Finance history for $symbol using YahooFinanceService: $e');
      // Re-throw a more specific exception if possible or a generic one
      throw Exception(
          'Failed to fetch history for $symbol from Yahoo Finance: $e');
    }
  } // End of fetchYahooHistory method
} // End of StockApiService class

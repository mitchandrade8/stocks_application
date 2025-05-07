// lib/services/stock_api_service.dart
import 'dart:convert'; // For json.decode
import 'package:http/http.dart' as http; // For API calls

// Corrected relative imports:
import '../models/stock_data.dart'; // To find StockData class
import '../config/api_constants.dart'; // To find alphaVantageApiKey

class StockApiService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  Future<StockData> fetchStockQuote(String symbol, String companyName) async {
    // Uses alphaVantageApiKey (should now be found)
    final String apiUrl =
        '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageApiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('Note') ||
            data['Global Quote'] == null ||
            (data['Global Quote'] as Map).isEmpty) {
          print('API Response: $data');
          throw Exception(
              'Failed to load stock data or API rate limit reached. Response: ${data.containsKey("Note") ? data["Note"] : "Empty quote data."}');
        }
        // Uses StockData.fromJson (should now be found as StockData class is imported)
        return StockData.fromJson(data, companyName);
      } else {
        throw Exception(
            'Failed to load stock data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock quote for $symbol: $e');
      // Re-throw or handle more gracefully
      throw Exception('Error fetching stock quote for $symbol: $e');
    }
  }
}

// lib/models/stock_data.dart
class StockData {
  final String symbol;
  final String companyName;
  final double price;
  final double change;
  final double changePercentage;

  StockData({
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.change,
    required this.changePercentage,
  });

  factory StockData.fromJson(Map<String, dynamic> json, String name) {
    final quote = json['Global Quote'];
    if (quote == null) {
      throw Exception(
          'Invalid stock data format from API: "Global Quote" missing.');
    }

    final priceStr = quote['05. price'] as String?;
    final changeStr = quote['09. change'] as String?;
    final changePercentStr = quote['10. change percent'] as String?;

    if (priceStr == null || changeStr == null || changePercentStr == null) {
      print('Problematic quote data: $quote'); // Add some logging
      throw Exception(
          'Missing required stock data fields (price, change, or change percent) from API.');
    }

    return StockData(
      symbol: quote['01. symbol'] as String,
      companyName: name,
      price: double.parse(priceStr),
      change: double.parse(changeStr),
      changePercentage: double.parse(changePercentStr.replaceAll('%', '')),
    );
  }
}

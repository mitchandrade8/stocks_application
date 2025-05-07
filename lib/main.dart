import 'package:flutter/material.dart';

// Your MyApp class remains the same
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Use super.key if your SDK constraint is >=2.17.0

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal), // Changed seed color for variety
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key}); // Or ({Key? key})

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAANG Stocks'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: const [
            // Added 'const' here as children are constant
            StockListItem(
              symbol: "META",
              companyName: "Meta Platforms Inc.",
              price: 320.75,
              change: 2.15,
              changePercentage: 0.67,
            ),
            StockListItem(
              symbol: "AAPL",
              companyName: "Apple Inc.",
              price: 172.40,
              change: -0.55,
              changePercentage: -0.32,
            ),
            StockListItem(
              symbol: "AMZN",
              companyName: "Amazon.com Inc.",
              price: 130.10,
              change: 1.80,
              changePercentage: 1.40,
            ),
            StockListItem(
              symbol: "NFLX",
              companyName: "Netflix Inc.",
              price: 440.50,
              change: -5.20,
              changePercentage: -1.17,
            ),
            StockListItem(
              symbol: "GOOGL",
              companyName: "Alphabet Inc. (Class A)",
              price: 135.60,
              change: 0.90,
              changePercentage: 0.67,
            ),
          ],
        ),
      ),
    );
  }
}

// New Widget for displaying a single stock item
class StockListItem extends StatelessWidget {
  final String symbol;
  final String companyName;
  final double price;
  final double change;
  final double changePercentage;

  const StockListItem({
    super.key, // Use super.key if your SDK constraint is >=2.17.0
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.change,
    required this.changePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = change >= 0 ? Colors.green : Colors.red;
    final String priceChangeFormatted =
        "${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercentage.toStringAsFixed(2)}%)";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3, // Add a bit of shadow
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left side: Symbol and Company Name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            // Right side: Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  priceChangeFormatted,
                  style: TextStyle(
                    fontSize: 14,
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

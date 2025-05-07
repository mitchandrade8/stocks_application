import 'package:flutter/material.dart';
import 'models/stock_data.dart'; // Import your model
import 'services/stock_api_service.dart'; // Import your service

// MyApp class remains the same (or as you last had it)
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

// Convert HomeScreen to StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockApiService _apiService = StockApiService();
  Future<StockData>?
      _stockDataFuture; // To hold the future result of our API call

  // Define the stock we want to fetch
  final String _symbolToFetch = "AAPL";
  final String _companyNameToFetch =
      "Apple Inc."; // Supplying name manually for now

  @override
  void initState() {
    super.initState();
    _fetchStockData(); // Call the fetch method when the widget is initialized
  }

  void _fetchStockData() {
    setState(() {
      // Trigger a new fetch. The FutureBuilder will handle the loading state.
      _stockDataFuture =
          _apiService.fetchStockQuote(_symbolToFetch, _companyNameToFetch);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Details - $_symbolToFetch'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStockData, // Add a refresh button
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          // Center the FutureBuilder
          child: FutureBuilder<StockData>(
            future: _stockDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // If the Future is still running, show a loading indicator
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                // If we run into an error, display it
                return Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                );
              } else if (snapshot.hasData) {
                // If we have data, display it using our StockListItem
                final stock = snapshot.data!;
                return StockListItem(
                  symbol: stock.symbol,
                  companyName: stock.companyName,
                  price: stock.price,
                  change: stock.change,
                  changePercentage: stock.changePercentage,
                );
              } else {
                // Otherwise, show a default message (shouldn't happen often with FutureBuilder)
                return const Text('No data available. Press refresh.');
              }
            },
          ),
        ),
      ),
    );
  }
}

// StockListItem widget remains the same (ensure it's in this file or imported)
class StockListItem extends StatelessWidget {
  final String symbol;
  final String companyName;
  final double price;
  final double change;
  final double changePercentage;

  const StockListItem({
    super.key,
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
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}

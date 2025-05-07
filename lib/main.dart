import 'package:flutter/material.dart';
import 'models/stock_data.dart'; // For StockData model
import 'services/stock_api_service.dart'; // For StockApiService
import 'screens/stock_detail_screen.dart'; // For navigating to StockDetailScreen

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
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green), // Or your preferred seed color
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockApiService _apiService = StockApiService();
  Future<List<StockData>>? _stockListFuture;

  final List<Map<String, String>> _faangStocksToFetch = [
    {'symbol': 'META', 'name': 'Meta Platforms Inc.'},
    {'symbol': 'AAPL', 'name': 'Apple Inc.'},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
    {'symbol': 'NFLX', 'name': 'Netflix Inc.'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc. (Class A)'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStockListData();
  }

  void _fetchStockListData() {
    setState(() {
      List<Future<StockData>> futures = _faangStocksToFetch.map((stockInfo) {
        return _apiService.fetchStockQuote(
            stockInfo['symbol']!, stockInfo['name']!);
      }).toList();
      _stockListFuture = Future.wait(futures);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAANG Stock Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStockListData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<StockData>>(
          future: _stockListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error fetching data: ${snapshot.error}\n\n(Could be API rate limits - Alpha Vantage free tier is 5 calls/minute. Try again in a minute.)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final stocks = snapshot.data!;
              return ListView.builder(
                itemCount: stocks.length,
                itemBuilder: (context, index) {
                  final stock = stocks[index];
                  return StockListItem(
                    symbol: stock.symbol,
                    companyName: stock.companyName,
                    price: stock.price,
                    change: stock.change,
                    changePercentage: stock.changePercentage,
                  );
                },
              );
            } else {
              return const Center(
                  child: Text('No data available. Press refresh.'));
            }
          },
        ),
      ),
    );
  }
}

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

    return InkWell(
      onTap: () {
        print('Tapped on stock: $symbol'); // Debugging print statement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(
              symbol: symbol,
              companyName: companyName,
            ),
          ),
        );
      },
      child: Card(
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
      ),
    );
  }
}

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
  final TextEditingController _symbolController =
      TextEditingController(); // For the dialog

  // State variables
  List<String> _watchlistSymbols = [
    'AAPL',
    'GOOGL',
    'META'
  ]; // Start with some defaults
  Map<String, StockData> _watchlistData = {}; // Map symbol to its StockData
  bool _isLoading = false;
  String? _error; // To store potential error messages

  @override
  void initState() {
    super.initState();
    _fetchWatchlistData(); // Fetch data for initial symbols
  }

  @override
  void dispose() {
    _symbolController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Fetch data for all symbols in the watchlist
  Future<void> _fetchWatchlistData({bool pullToRefresh = false}) async {
    if (!pullToRefresh) {
      // Only show loading indicator on initial load or add
      setState(() {
        _isLoading = true;
        _error = null; // Clear previous errors
      });
    }

    // Create a temporary map to hold new data
    Map<String, StockData> newData = {};
    List<String> errors = [];

    // Use Alpha Vantage fetchStockQuote (requires name - fetch it or use symbol?)
    // Let's modify fetchStockQuote slightly for this use case, or fetch name separately.
    // Easiest for now: Pass symbol as name to fetchStockQuote and ignore it later.
    for (String symbol in _watchlistSymbols) {
      try {
        // We pass symbol also as companyName - fetchStockQuote ignores it if using AlphaVantage
        // but might need adjustment if you switch quote provider later.
        final stockData = await _apiService.fetchStockQuote(symbol, symbol);
        newData[symbol] = stockData;
      } catch (e) {
        print("Error fetching quote for $symbol: $e");
        errors.add(symbol); // Keep track of failed symbols
      }
    }

    // Update state only if the widget is still mounted
    if (mounted) {
      setState(() {
        _watchlistData = newData; // Update with successfully fetched data
        _isLoading = false;
        if (errors.isNotEmpty) {
          _error = "Couldn't fetch data for: ${errors.join(', ')}";
        } else {
          _error = null;
        }
      });
    }
  }

  // Add a stock symbol to the watchlist
  void _addStockToWatchlist(String symbol) {
    final upperSymbol = symbol.toUpperCase().trim();
    if (upperSymbol.isNotEmpty && !_watchlistSymbols.contains(upperSymbol)) {
      setState(() {
        _watchlistSymbols.add(upperSymbol);
        _error = null; // Clear error when adding
        // Optionally fetch just the new stock data immediately, or wait for full refresh
        // Let's trigger a full refresh for simplicity now
        _fetchWatchlistData();
        // TODO: Persist _watchlistSymbols to local storage here
      });
    }
    _symbolController.clear(); // Clear the text field
  }

  // Remove a stock symbol from the watchlist
  void _removeStockFromWatchlist(String symbol) {
    setState(() {
      _watchlistSymbols.remove(symbol);
      _watchlistData.remove(symbol); // Remove from displayed data immediately
      // TODO: Update persisted list in local storage here
    });
  }

  // Show the dialog to add a new stock
  Future<void> _showAddStockDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Stock Symbol'),
          content: TextField(
            controller: _symbolController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'e.g., MSFT'),
            onSubmitted: (value) {
              // Add on submit
              _addStockToWatchlist(value);
              Navigator.of(context).pop(); // Close dialog on submit
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                _symbolController.clear(); // Clear on cancel
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                _addStockToWatchlist(_symbolController.text);
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            // Keep refresh button
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () => _fetchWatchlistData(
                pullToRefresh: true), // Allow refresh without loading indicator
          ),
        ],
      ),
      body: _buildBody(), // Use helper method for body
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
        tooltip: 'Add Stock',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper widget to build the body content
  Widget _buildBody() {
    if (_isLoading && _watchlistData.isEmpty) {
      // Show loading only on initial load
      return const Center(child: CircularProgressIndicator());
    }
    if (_watchlistSymbols.isEmpty) {
      return const Center(
          child: Text('Your watchlist is empty.\nTap + to add a stock.',
              textAlign: TextAlign.center));
    }
    // Combine error display with the list
    return Column(
      children: [
        if (_error != null) // Show error if present
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_error!,
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        Expanded(
          // Make ListView take remaining space
          child: RefreshIndicator(
            // Add pull-to-refresh
            onRefresh: () => _fetchWatchlistData(pullToRefresh: true),
            child: ListView.builder(
              itemCount: _watchlistSymbols.length,
              itemBuilder: (context, index) {
                final symbol = _watchlistSymbols[index];
                final stock = _watchlistData[symbol]; // Get data from map

                // If data for this symbol hasn't loaded yet or failed
                if (stock == null) {
                  // Optionally show a placeholder or loading state per item
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 4.0),
                    child: ListTile(
                      title: Text(symbol,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500])),
                      trailing: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }

                // If data is loaded, show the Dismissible StockListItem
                return Dismissible(
                  key: ValueKey(symbol), // Unique key is required
                  direction:
                      DismissDirection.endToStart, // Swipe left to dismiss
                  onDismissed: (direction) {
                    _removeStockFromWatchlist(symbol);
                    // Show a snackbar confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$symbol removed from watchlist')),
                    );
                  },
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  child: StockListItem(
                    // Use the modified StockListItem
                    symbol: stock.symbol,
                    // companyName: stock.companyName, // Removed
                    price: stock.price,
                    change: stock.change,
                    changePercentage: stock.changePercentage,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
} // End _HomeScreenState

class StockListItem extends StatelessWidget {
  final String symbol;
  // final String companyName; // Removed
  final double price;
  final double change;
  final double changePercentage;

  const StockListItem({
    super.key,
    required this.symbol,
    // required this.companyName, // Removed
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
        print('Tapped on stock: $symbol');
        Navigator.push(
          context,
          MaterialPageRoute(
            // Pass symbol, but maybe fetch name inside detail screen later
            builder: (context) => StockDetailScreen(
              symbol: symbol,
              companyName: symbol, // Pass symbol as name for now
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(
            vertical: 6.0, horizontal: 4.0), // Adjusted margin
        elevation: 2, // Slightly less elevation
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 10.0, horizontal: 16.0), // Adjusted padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Left side: Symbol Only
              Text(
                symbol,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage

// Ensure paths are correct based on your project structure
import 'models/stock_data.dart';
import 'services/stock_api_service.dart';
import 'screens/stock_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Use super.key if SDK constraint >= 2.17.0, otherwise use Key? key
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo), // Example seed color
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  // Use super.key if SDK constraint >= 2.17.0, otherwise use Key? key
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockApiService _apiService = StockApiService();
  final TextEditingController _symbolController = TextEditingController();

  // State variables
  List<String> _watchlistSymbols = []; // Start empty, load from prefs
  Map<String, StockData?> _watchlistData =
      {}; // Map symbol to its StockData (nullable for loading state)
  bool _isLoading = true; // Start loading initially
  String? _error; // To store potential error messages
  bool _isPrefsLoaded = false; // Flag to track if prefs have been loaded

  // Key for saving/loading watchlist in SharedPreferences
  static const String _watchlistPrefKey = 'stockWatchlist';

  @override
  void initState() {
    super.initState();
    // Load the watchlist from storage first, then fetch data
    _loadWatchlistAndFetchData();
  }

  @override
  void dispose() {
    _symbolController.dispose(); // Dispose the controller
    super.dispose();
  }

  // --- SharedPreferences Logic ---

  // Combines loading and default handling
  Future<void> _loadWatchlistAndFetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    List<String> loadedSymbols = [];
    bool keyExisted = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      keyExisted = prefs.containsKey(_watchlistPrefKey);
      loadedSymbols = prefs.getStringList(_watchlistPrefKey) ?? [];
      print("--- Loaded Watchlist ---");
      print("Key '$_watchlistPrefKey' existed: $keyExisted");
      print("Loaded symbols: $loadedSymbols");
      print("------------------------");
    } catch (e) {/* ... error handling ... */}

    if (mounted) {
      setState(() {
        _watchlistSymbols = loadedSymbols; /* ... */
      });
    }

    if (!keyExisted && _watchlistSymbols.isEmpty) {
      print("Watchlist key didn't exist & list empty. Adding defaults.");
      _watchlistSymbols = ['AAPL', 'GOOGL', 'META'];
      await _saveWatchlist(); // <<< Ensure this await is here
      if (mounted) {/* ... */}
    }

    _isPrefsLoaded = true;
    await _fetchWatchlistData(pullToRefresh: false);
  }

  Future<void> _saveWatchlist() async {
    // Ensure widget is still mounted before performing async operations affecting state/prefs
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      print("--- Saving Watchlist ---");
      print("Symbols to save: $_watchlistSymbols");

      // *** CHECK THE RETURN VALUE ***
      final bool success =
          await prefs.setStringList(_watchlistPrefKey, _watchlistSymbols);

      // *** PRINT SUCCESS OR FAILURE ***
      if (success) {
        print("SharedPreferences save successful (returned true).");
      } else {
        // This indicates the platform plugin reported failure
        print("!!! SharedPreferences save FAILED (returned false).");
      }
      print("------------------------");
    } catch (e) {
      print("!!! Error saving watchlist (exception): $e");
    }
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchWatchlistData({bool pullToRefresh = false}) async {
    // Don't fetch if prefs haven't loaded, unless it's a user-initiated refresh
    if (!_isPrefsLoaded && !pullToRefresh) {
      print("Skipping fetch: Prefs not loaded yet.");
      // Ensure loading is turned off if we skip fetching after initial load attempt
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    // Set loading state appropriately
    if (!pullToRefresh && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() {
        _error = null;
      }); // Clear error on pull-to-refresh
    }

    Map<String, StockData?> currentData =
        Map.from(_watchlistData); // Use existing data map
    List<String> errors = [];
    List<String> symbolsToFetch =
        List.from(_watchlistSymbols); // Use current watchlist

    print("Fetching data for symbols: $symbolsToFetch");

    for (String symbol in symbolsToFetch) {
      if (!mounted)
        return; // Check if widget is still mounted before/during loop
      try {
        // Pass symbol also as companyName for now
        final stockData = await _apiService.fetchStockQuote(symbol, symbol);
        if (mounted) {
          // Check again before updating state inside loop
          setState(() {
            currentData[symbol] = stockData; // Update map as data arrives
          });
        }
      } catch (e) {
        print("Error fetching quote for $symbol: $e");
        errors.add(symbol);
        if (mounted) {
          setState(() {
            currentData[symbol] = null; // Explicitly mark as failed/null
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _watchlistData = currentData; // Assign the updated map
        _isLoading = false; // Turn off loading indicator
        if (errors.isNotEmpty) {
          _error = "Couldn't update data for: ${errors.join(', ')}";
        } else {
          _error = null;
        }
      });
    }
  }

  // --- Add/Remove Logic ---

   void _addStockToWatchlist(String symbol) async {
    final upperSymbol = symbol.toUpperCase().trim();
    if (upperSymbol.isNotEmpty && !_watchlistSymbols.contains(upperSymbol)) {
      print("Adding symbol: $upperSymbol");
      setState(() {
        _watchlistSymbols.add(upperSymbol);
        _error = null;
        _watchlistData[upperSymbol] = null;
      });
      await _saveWatchlist(); // Await the save operation

      // *** ADDED DEBUG DELAY - REMOVE FOR PRODUCTION ***
      await Future.delayed(const Duration(milliseconds: 500));
      print("Debug delay after add/save complete.");
      // *** END DEBUG DELAY ***

      _fetchWatchlistData();
    }
    _symbolController.clear();
  }

  void _removeStockFromWatchlist(String symbol) async {
    print("Removing symbol: $symbol");
    setState(() {
      _watchlistSymbols.remove(symbol);
      _watchlistData.remove(symbol);
    });
    await _saveWatchlist(); // Await the save operation

    // *** ADDED DEBUG DELAY - REMOVE FOR PRODUCTION ***
    await Future.delayed(const Duration(milliseconds: 500));
    print("Debug delay after remove/save complete.");
    // *** END DEBUG DELAY ***
  }

  // --- Dialog Logic ---
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
              // Add on pressing Enter/Submit
              if (value.trim().isNotEmpty) {
                _addStockToWatchlist(value);
                Navigator.of(context).pop(); // Close dialog
              }
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
                if (_symbolController.text.trim().isNotEmpty) {
                  _addStockToWatchlist(_symbolController.text);
                  Navigator.of(context).pop(); // Close dialog
                }
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            // Only enable refresh if not already loading
            onPressed: _isLoading
                ? null
                : () => _fetchWatchlistData(pullToRefresh: true),
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
    // Show loading indicator only on initial load when list/data is empty
    if (_isLoading && _watchlistData.isEmpty && _watchlistSymbols.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // Show empty message if list is empty AND prefs have loaded
    if (_watchlistSymbols.isEmpty && _isPrefsLoaded) {
      return const Center(
          child: Text('Your watchlist is empty.\nTap + to add a stock.',
              textAlign: TextAlign.center));
    }
    // If prefs haven't loaded show loading (covers initial state before load finishes)
    if (!_isPrefsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Build the list potentially showing errors at the top
    return Column(
      children: [
        if (_error != null) // Show error message if present
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(_error!,
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
        Expanded(
          // Make ListView take remaining space
          child: RefreshIndicator(
            // Add pull-to-refresh
            onRefresh: () => _fetchWatchlistData(pullToRefresh: true),
            child: ListView.builder(
              // Add padding to list itself
              padding:
                  const EdgeInsets.only(bottom: 80), // Ensure space for FAB
              itemCount: _watchlistSymbols.length,
              itemBuilder: (context, index) {
                final symbol = _watchlistSymbols[index];
                // Use nullable StockData directly from the map
                final StockData? stock = _watchlistData[symbol];

                // Check if data is loading (exists in symbol list but not yet in data map)
                // or if it explicitly failed (null in map after fetch attempt)
                bool isItemLoading =
                    !_watchlistData.containsKey(symbol) || stock == null;
                // Determine if there was a specific error for *this* symbol
                bool itemHadError =
                    (_error?.contains(symbol) ?? false) && stock == null;

                // Build Dismissible item
                return Dismissible(
                  key: ValueKey(symbol), // Use symbol for unique key
                  direction: DismissDirection.endToStart, // Swipe direction
                  onDismissed: (direction) {
                    _removeStockFromWatchlist(symbol);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$symbol removed from watchlist'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  background: Container(
                    // Background shown during swipe
                    color: Colors.redAccent[700],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  child:
                      (isItemLoading) // Show loading/error state or actual data
                          ? Card(
                              // Placeholder card for loading/error state
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6.0, horizontal: 4.0),
                              child: ListTile(
                                title: Text(symbol,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600])),
                                trailing: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        itemHadError // Show error icon if specific error occurred
                                            ? Tooltip(
                                                message: "Failed to load",
                                                child: Icon(Icons.error_outline,
                                                    color: Colors.orange[800],
                                                    size: 24))
                                            : const CircularProgressIndicator(
                                                strokeWidth: 2)),
                              ),
                            )
                          : StockListItem(
                              // Show actual data using StockListItem
                              symbol: stock.symbol,
                              price: stock.price,
                              change: stock.change,
                              changePercentage: stock.changePercentage,
                            ),
                ); // End Dismissible
              }, // End itemBuilder
            ), // End ListView.builder
          ), // End RefreshIndicator
        ), // End Expanded
      ], // End Column children
    ); // End Column
  } // End _buildBody
} // End _HomeScreenState

// --- StockListItem Widget ---
// (Ensure this is present below, same as the last version without companyName)
class StockListItem extends StatelessWidget {
  final String symbol;
  final double price;
  final double change;
  final double changePercentage;

  const StockListItem({
    super.key,
    required this.symbol,
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
            builder: (context) => StockDetailScreen(
              symbol: symbol,
              companyName: symbol, // Passing symbol as name for now
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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

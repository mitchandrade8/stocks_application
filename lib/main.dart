import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp()); // Or a more specific name like StockTrackerApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Promethan Financials', 
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // app's first screen
    );
  }
}

// Create your first screen (e.g., HomeScreen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promethan Financials'),
      ),
      body: const Center(
        child: Text('Welcome to Promethan Financial!'),
      ),
    );
  }
}

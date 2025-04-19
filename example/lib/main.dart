import 'package:flutter/material.dart';
import 'package:auto_scroll_row/auto_scroll_row.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Scroll Row Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExamplesScreen(),
    );
  }
}

class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoScrollRow Examples'),
        backgroundColor: Colors.blueAccent.withValues(alpha: .7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Standard constructor with direct children
            const Text(
              'Standard Constructor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AutoScrollRow(
                scrollDuration: const Duration(minutes: 4),
                reverse: false,
                enableUserScroll: true,
                children: List.generate(
                  10,
                  (index) => Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade300,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Item $index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Example 2: Builder constructor for efficient rendering
            const Text(
              'Builder Constructor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AutoScrollRow.builder(
                itemCount:
                    50, // Large number of items to demonstrate efficiency
                scrollDuration: const Duration(minutes: 10),
                reverse: true, // Scrolling from right to left
                enableUserScroll: true,
                itemBuilder: (context, index) {
                  // Color based on index for visual distinction
                  final color = Color.fromARGB(
                    255,
                    (index * 20) % 255,
                    150,
                    (255 - (index * 10) % 255),
                  );

                  return Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Item $index',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.arrow_back, color: Colors.white),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Example 3: Builder with dynamic content
            const Text(
              'Dynamic Content Example',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AutoScrollRow.builder(
                itemCount: 20,
                scrollDuration: const Duration(minutes: 5),
                itemBuilder: (context, index) {
                  // Different widgets based on index
                  if (index % 3 == 0) {
                    // Card with image placeholder
                    return Container(
                      width: 180,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 100,
                            width: 160,
                            color: Colors.orange.shade300,
                            child: const Icon(Icons.image,
                                size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Photo Item $index',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ],
                      ),
                    );
                  } else if (index % 3 == 1) {
                    // Info card
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade300, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            'Info Card $index',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Some information here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: .9),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Simple card
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

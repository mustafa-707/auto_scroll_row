import 'package:flutter/material.dart';
import 'package:auto_scroll_row/auto_scroll_row.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Scroll Row Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('AutoScrollRow Example')),
        body: Center(
          child: AutoScrollRow(
            children: List.generate(
              10,
              (index) => Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(8),
                color: Colors.blueAccent,
                child: Center(child: Text('Item $index')),
              ),
            ),
            scrollDuration: const Duration(minutes: 15),
            reverse: false,
            enableUserScroll: true,
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key});

  Future<Map<String, String>> _getRandomQuote() async {
    final String response = await rootBundle.loadString('assets/quotes.json');
    final List<dynamic> data = json.decode(response);
    final random = Random();
    final item = data[random.nextInt(data.length)];
    return {"quote": item["quote"], "author": item["author"]};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Wir definieren die Farben fest vorab
    // 0x1A... entspricht ca. 10% Deckkraft, 0x0D... ca. 5%
    final cardBgColor = isDark 
        ? const Color(0x1AFFFFFF) // Weiß mit 10% Deckkraft
        : Colors.white;
    
    final borderColor = isDark 
        ? const Color(0x1AFFFFFF) 
        : const Color(0x0D000000); // Schwarz mit 5% Deckkraft

    final lineIndicatorColor = const Color(0x80FFD740); // Amber mit 50% Deckkraft

    return FutureBuilder<Map<String, String>>(
      future: _getRandomQuote(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        return Container(
          width: double.infinity, 
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(30), 
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const Icon(Icons.format_quote, color: Colors.amberAccent, size: 40),
              const SizedBox(height: 10),
              Text(
                snapshot.data!['quote']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 2,
                width: 40,
                color: lineIndicatorColor,
              ),
              const SizedBox(height: 15),
              Text(
                snapshot.data!['author']!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
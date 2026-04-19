import 'package:flutter/material.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: kBrandRed.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Search Pages',
              style: TextStyle(color: kTextDark, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Coming Soon',
              style: TextStyle(color: kTextMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
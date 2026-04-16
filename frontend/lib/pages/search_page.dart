import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SearchPage({super.key, required this.userData});

  @override
  State<SearchPage> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Search Page', style: TextStyle(color: Colors.white)),
    );
  }
}
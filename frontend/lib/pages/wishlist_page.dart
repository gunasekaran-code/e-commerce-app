import 'package:flutter/material.dart';

class WishlistPage extends StatefulWidget {  // ✅ Changed from SearchPage
  final Map<String, dynamic> userData;
  const WishlistPage({super.key, required this.userData});

  @override
  State<WishlistPage> createState() => _WishlistPageState(); // ✅ Changed

  }

class _WishlistPageState extends State<WishlistPage> { // ✅ Changed
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Wishlist Page', style: TextStyle(color: Colors.white)), // ✅ Changed
    );
  }
}
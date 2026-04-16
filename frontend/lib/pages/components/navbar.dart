import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../product_detail_page.dart';
import '../user_home.dart';      // ✅
import '../search_page.dart';   // ✅
import '../wishlist_page.dart'; // ✅
import '../profile_page.dart';  // ✅

class UserHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserHomePage({super.key, required this.userData});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B11),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            UserHomePage(userData: widget.userData),     // ✅ index 0
            SearchPage(userData: widget.userData),   // ✅ index 1
            WishlistPage(userData: widget.userData), // ✅ index 2
            ProfilePage(userData: widget.userData),  // ✅ index 3
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B11),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.lightGreenAccent,
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled),      label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search),            label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border),   label: 'Favorites'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),    label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ProductCard stays here so screens can import it from user_home.dart
class ProductCard extends StatelessWidget {
  final Product product;
  final Map<String, dynamic> userData;

  const ProductCard({super.key, required this.product, required this.userData});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: product.id,
            userData: userData,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 110,
                        color: Colors.grey.withOpacity(0.15),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white24, size: 36),
                      ),
                    )
                  : Container(
                      height: 110,
                      color: Colors.grey.withOpacity(0.15),
                      child: const Icon(Icons.shopping_bag,
                          color: Colors.white24, size: 36),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
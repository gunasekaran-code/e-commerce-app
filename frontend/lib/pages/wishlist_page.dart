import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/wishlist_service.dart';
import 'product_detail_page.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kBrandRedSoft = Color(0xFFFFE5E6);
const Color kBgLight = Color(0xFFFDF7F7);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);

class WishlistPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const WishlistPage({super.key, required this.userData});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;
  late StreamSubscription<WishlistChangeEvent> _wishlistSubscription;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
    _listenToWishlistChanges();
  }

  void _listenToWishlistChanges() {
    _wishlistSubscription = WishlistService().wishlistChangeStream.listen((event) {
      if (mounted) {
        if (event.isAdded) {
          // Product was added to wishlist, reload the wishlist
          _loadWishlist();
        } else {
          // Product was removed, update the UI immediately
          setState(() {
            wishlistItems.removeWhere((item) => item['product_id'] == event.productId);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _wishlistSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadWishlist() async {
    setState(() => isLoading = true);
    try {
      final items = await ApiService.getWishlist(widget.userData['id']);
      setState(() {
        wishlistItems = List<Map<String, dynamic>>.from(items);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: $e')),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(int productId) async {
    try {
      final success = await ApiService.removeFromWishlist(
        userId: widget.userData['id'],
        productId: productId,
      );
      if (success) {
        setState(() {
          wishlistItems.removeWhere((item) => item['product_id'] == productId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from wishlist'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextDark),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kBrandRed),
            )
          : wishlistItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 80, color: kBrandRed.withOpacity(0.3)),
                      const SizedBox(height: 20),
                      const Text(
                        'No Favorites Yet',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add products to your favorites to see them here',
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kBrandRed,
                  onRefresh: _loadWishlist,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: wishlistItems.length,
                    itemBuilder: (context, index) {
                      final item = wishlistItems[index];
                      return WishlistItemCard(
                        item: item,
                        userData: widget.userData,
                        onRemove: () =>
                            _removeFromWishlist(item['product_id']),
                      );
                    },
                  ),
                ),
    );
  }
}

class WishlistItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> userData;
  final VoidCallback onRemove;

  const WishlistItemCard({
    super.key,
    required this.item,
    required this.userData,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: item['product_id'],
              userData: userData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: kBrandRed.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: item['image'] != null
                  ? Image.network(
                      item['image'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 120,
                        color: kBrandRedSoft,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: kBrandRed,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: kBrandRedSoft,
                      child: const Icon(
                        Icons.shopping_bag,
                        color: kBrandRed,
                        size: 32,
                      ),
                    ),
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product Name and Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] ?? 'Product',
                          style: const TextStyle(
                            color: kTextDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['category'] ?? 'N/A',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${double.parse(item['price'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: kBrandRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              item['rating'].toString(),
                              style: const TextStyle(
                                color: kTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Remove Button
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  decoration: BoxDecoration(
                    color: kBrandRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: kBrandRed,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
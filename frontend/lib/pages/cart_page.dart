import 'package:flutter/material.dart';
import '../services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kBackground = Colors.white;
const Color kSurface = Color(0xFFF7F7F7);
const Color kBorder = Color(0xFFEAEAEA);

class CartPage extends StatefulWidget {
  final int userId;
  const CartPage({super.key, required this.userId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List cartItems = [];
  bool loading = true;
  String promoCode = '';
  bool promoApplied = false;
  double deliveryFee = 5.00;
  double discountPercent = 0;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  loadCart() async {
    final items = await ApiService.getCart(widget.userId);
    setState(() {
      cartItems = items;
      loading = false;
    });
  }

  double get subtotal => cartItems.fold(
      0, (sum, item) => sum + (item['price'] * item['quantity']));

  double get total => subtotal + deliveryFee - (subtotal * discountPercent / 100);

  void applyPromo() {
    if (promoCode.trim().toUpperCase() == 'ADJ3AK') {
      setState(() {
        promoApplied = true;
        discountPercent = 40;
      });
    }
  }

  void updateQty(int index, int delta) async {
    final newQuantity = (cartItems[index]['quantity'] + delta).clamp(1, 99);
    final productId = cartItems[index]['product_id'];
    
    // Optimistically update UI
    setState(() {
      cartItems[index]['quantity'] = newQuantity;
    });
    
    // Update in backend
    final success = await ApiService.updateCartItem(
      userId: widget.userId,
      productId: productId,
      quantity: newQuantity,
    );
    
    if (!success) {
      // Revert if update fails
      setState(() {
        cartItems[index]['quantity'] = cartItems[index]['quantity'] - delta;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update quantity'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void removeItem(int index) async {
    final productId = cartItems[index]['product_id'];
    final productName = cartItems[index]['product_name'];
    
    // Store in case we need to restore
    final removedItem = cartItems[index];
    
    // Optimistically remove from UI
    setState(() => cartItems.removeAt(index));
    
    // Remove from backend
    final success = await ApiService.removeFromCart(
      userId: widget.userId,
      productId: productId,
    );
    
    if (!success) {
      // Restore if removal fails
      setState(() => cartItems.insert(index, removedItem));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove item'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName removed from cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
        'My Cart',
        style: TextStyle(
          color: kBrandRed,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.more_horiz, color: Colors.black),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator( color: Color(0xFFE4252A)))
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: const Color(0xFFE4252A).withOpacity(0.3)),
                      const SizedBox(height: 20),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add items to get started',
                        style: TextStyle(
                          color: kTextMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE4252A),
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
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFFE4252A),
                        onRefresh: () async {
                          await Future.delayed(const Duration(milliseconds: 500));
                          loadCart();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // Product image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(item['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                              Icons.image, color: Colors.grey)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(item['product_name'],
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16)),
                                            ),
                                            GestureDetector(
                                              onTap: () => removeItem(index),
                                              child: const Icon(Icons.close,
                                                  size: 18, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(item['variant'] ?? '',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                '\₹${(item['price'] as num).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            // Qty controls
                                                  Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey[300]!),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  _qtyButton(Icons.remove, () =>
                                                      updateQty(index, -1)),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 12),
                                                    child: Text(
                                                        '${item['quantity']}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600)),
                                                  ),
                                                  _qtyButton(Icons.add, () =>
                                                      updateQty(index, 1),
                                                      highlight: true),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Bottom section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          // Promo code
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) => promoCode = v,
                                    decoration: const InputDecoration(
                                      hintText: 'Promo code',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (promoApplied)
                              Row(children: [
                                Text('Promocode applied',
                                    style: TextStyle(
                                        color: const Color.fromARGB(255, 160, 67, 67),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle,
                                    color: Color(0xFFE4252A),  size: 18),
                              ])
                            else
                              GestureDetector(
                                onTap: applyPromo,
                                child: const Text('Apply',
                                    style: TextStyle(
                                        color: Color(0xFFE4252A),
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _summaryRow('Subtotal:', '\₹${subtotal.toStringAsFixed(2)}'),
                      _summaryRow('Delivery Fee:', '\₹${deliveryFee.toStringAsFixed(2)}'),
                      if (promoApplied)
                        _summaryRow('Discount:', '${discountPercent.toInt()}%'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE4252A), 
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {},
                          child: Text(
                              'Checkout for \₹ ${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap,
      {bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFE4252A).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18, color: highlight ? Color(0xFFE4252A) : Colors.grey[600]),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

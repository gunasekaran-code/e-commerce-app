import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'add_product.dart';
import 'edit_product.dart';

class AdminHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AdminHomePage({super.key, required this.userData});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<Product> products = [];
  bool isLoading = true;
  bool showDeleted = false;
  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);
    final fetchedProducts = await ApiService.getAllProductsAdmin();
    setState(() {
      products = fetchedProducts;
      isLoading = false;
    });
  }

  Future<void> softDeleteProduct(int id) async {
    final success = await ApiService.softDeleteProduct(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      fetchProducts();
    }
  }

  Future<void> restoreProduct(int id) async {
    final success = await ApiService.restoreProduct(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
      fetchProducts();
    }
  }

  void _editProduct(Product product) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                EditProductPage(userData: widget.userData, product: product),
          ),
        )
        .then((_) => fetchProducts()); // Refresh products after editing
  }

  List<Product> get filteredProducts {
    return showDeleted
        ? products.where((p) => p.delFlag).toList()
        : products.where((p) => !p.delFlag).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B11),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard', style: TextStyle(fontSize: 18)),
            Text(
              'Welcome, ${widget.userData['full_name']}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.lightGreenAccent,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showDeleted ? Icons.inventory : Icons.delete_outline,
              color: showDeleted ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() => showDeleted = !showDeleted);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.lightGreenAccent),
            )
          : Column(
              children: [
                // Stats Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        'Active',
                        products.where((p) => !p.delFlag).length.toString(),
                        Colors.green,
                      ),
                      _buildStat(
                        'Deleted',
                        products.where((p) => p.delFlag).length.toString(),
                        Colors.red,
                      ),
                      _buildStat(
                        'Total',
                        products.length.toString(),
                        Colors.blue,
                      ),
                    ],
                  ),
                ),

                // Product List
                Expanded(
                  child: displayProducts.isEmpty
                      ? Center(
                          child: Text(
                            showDeleted
                                ? 'No deleted products'
                                : 'No active products',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: Colors.lightGreenAccent,
                          onRefresh: fetchProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: displayProducts.length,
                            itemBuilder: (context, index) {
                              final product = displayProducts[index];
                              return AdminProductCard(
                                product: product,
                                onDelete: () => softDeleteProduct(product.id),
                                onRestore: () => restoreProduct(product.id),
                                onEdit: () => _editProduct(product),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddProductPage(userData: widget.userData),
            ),
          );
        },
        backgroundColor: Colors.lightGreenAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class AdminProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onEdit;

  const AdminProductCard({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onRestore,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.delFlag
              ? Colors.red.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrl != null
              ? Image.network(
                  product.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.withOpacity(0.2),
                      child: const Icon(Icons.image_not_supported, size: 30),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.withOpacity(0.2),
                  child: const Icon(Icons.shopping_bag, size: 30),
                ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            color: product.delFlag
                ? Colors.white.withOpacity(0.5)
                : Colors.white,
            fontWeight: FontWeight.bold,
            decoration: product.delFlag ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '\₹${product.price.toStringAsFixed(2)} • Stock: ${product.stock}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            if (product.delFlag)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DELETED',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: product.delFlag
            ? IconButton(
                icon: const Icon(Icons.restore, color: Colors.green),
                onPressed: onRestore,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
      ),
    );
  }
}

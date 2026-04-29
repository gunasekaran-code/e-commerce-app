class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int? categoryId;
  final String? imageUrl;
  final List<String> images;
  final int stock;
  final double rating;
  final bool delFlag;
  final bool isInStock;
  final String createdAt;
  final int? skuId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.categoryId,
    this.imageUrl,
    required this.images,
    required this.stock,
    required this.rating,
    required this.delFlag,
    required this.isInStock,
    required this.createdAt,
    this.skuId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];
    
    // Parse category safely - prioritize display name, then name, then convert ID to string
    String categoryValue;
    if (json['category_display_name'] != null && json['category_display_name'].toString().isNotEmpty) {
      categoryValue = json['category_display_name'].toString();
    } else if (json['category_name'] != null && json['category_name'].toString().isNotEmpty) {
      categoryValue = json['category_name'].toString();
    } else if (json['category'] != null) {
      categoryValue = json['category'].toString();
    } else {
      categoryValue = 'Unknown';
    }

    // Parse category ID
    int? categoryIdValue;
    if (json['category'] is int) {
      categoryIdValue = json['category'] as int;
    } else if (json['category'] is String) {
      categoryIdValue = int.tryParse(json['category'] as String);
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: categoryValue,
      categoryId: categoryIdValue,
      imageUrl: json['image_url'],
      images: rawImages
          .map(
            (e) => e is Map<String, dynamic>
                ? e['image_url']?.toString()
                : e?.toString(),
          )
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(),
      stock: json['stock'],
      rating: double.parse(json['rating'].toString()),
      delFlag: json['del_flag'] ?? false,
      isInStock: json['is_in_stock'] ?? false,
      createdAt: json['created_at'],
      skuId: json['sku_id'],
    );
  }
}
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
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
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'],
      imageUrl: json['image_url'],
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e['image_url'] as String).toList() ??
              [],
      stock: json['stock'],
      rating: double.parse(json['rating'].toString()),
      delFlag: json['del_flag'] ?? false,
      isInStock: json['is_in_stock'] ?? false,
      createdAt: json['created_at'],
      skuId: json['sku_id'],
    );
  }
}
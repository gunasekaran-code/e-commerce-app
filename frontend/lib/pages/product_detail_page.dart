// import 'package:flutter/material.dart';
// import '../models/product_model.dart';
// import '../services/api_service.dart';

// class ProductDetailPage extends StatefulWidget {
//   final int productId;
//   final Map<String, dynamic> userData;

//   const ProductDetailPage({
//     super.key,
//     required this.productId,
//     required this.userData,
//   });

//   @override
//   State<ProductDetailPage> createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   Product? product;
//   bool isLoading = true;
//   double exchangeRate = 83.0; // Default USD to INR rate

//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }

//   Future<void> fetchData() async {
//     await Future.wait([fetchProduct(), fetchExchangeRate()]);
//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> fetchProduct() async {
//     product = await ApiService.getProductDetail(widget.productId);
//   }

//   Future<void> fetchExchangeRate() async {
//     exchangeRate = await ApiService.getExchangeRate();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0D1B11),
//         appBar: AppBar(backgroundColor: Colors.black87),
//         body: const Center(
//           child: CircularProgressIndicator(color: Colors.red),
//         ),
//       );
//     }

//     if (product == null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0D1B11),
//         appBar: AppBar(backgroundColor: Colors.black87),
//         body: const Center(
//           child: Text(
//             'Product not found',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFF0D1B11),
//       appBar: AppBar(
//         backgroundColor: Colors.black87,
//         title: const Text('Product Details'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Image
//             if (product!.imageUrl != null)
//               Image.network(
//                 product!.imageUrl!,
//                 width: double.infinity,
//                 height: 300,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     width: double.infinity,
//                     height: 300,
//                     color: Colors.grey.withOpacity(0.2),
//                     child: const Icon(
//                       Icons.image_not_supported,
//                       size: 80,
//                       color: Colors.white38,
//                     ),
//                   );
//                 },
//               )
//             else
//               Container(
//                 width: double.infinity,
//                 height: 300,
//                 color: Colors.grey.withOpacity(0.2),
//                 child: const Icon(
//                   Icons.shopping_bag,
//                   size: 80,
//                   color: Colors.white38,
//                 ),
//               ),

//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Product Name
//                   Text(
//                     product!.name,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),

//                   // Rating and Category
//                   Row(
//                     children: [
//                       const Icon(Icons.star, color: Colors.amber, size: 20),
//                       const SizedBox(width: 4),
//                       Text(
//                         product!.rating.toString(),
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.7),
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.lightGreenAccent.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           product!.category.toUpperCase(),
//                           style: const TextStyle(
//                             color: Colors.lightGreenAccent,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Price
//                   Text(
//                     '₹${(product!.price * exchangeRate).toStringAsFixed(2)}',
//                     style: const TextStyle(
//                       color: Colors.lightGreenAccent,
//                       fontSize: 32,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Stock Status
//                   Row(
//                     children: [
//                       Icon(
//                         product!.isInStock ? Icons.check_circle : Icons.cancel,
//                         color: product!.isInStock ? Colors.green : Colors.red,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         product!.isInStock
//                             ? 'In Stock (${product!.stock} units)'
//                             : 'Out of Stock',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.7),
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Description
//                   const Text(
//                     'Description',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     product!.description,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 16,
//                       height: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Add to Cart Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton.icon(
//                       onPressed: product!.isInStock
//                           ? () async {
//                               bool success = await ApiService.addToCart(
//                                 userId: widget.userData['id'],
//                                 productId: product!.id,
//                               );

//                               if (success) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('Added to cart!'),
//                                     backgroundColor: Colors.green,
//                                   ),
//                                 );
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('Failed to add to cart'),
//                                     backgroundColor: Colors.red,
//                                   ),
//                                 );
//                               }
//                             }
//                           : null,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.lightGreenAccent,
//                         foregroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         disabledBackgroundColor: Colors.grey,
//                       ),
//                       icon: const Icon(Icons.shopping_cart),
//                       label: Text(
//                         product!.isInStock ? 'ADD TO CART' : 'OUT OF STOCK',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> userData;

  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.userData,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? product;
  bool isLoading = true;
  double exchangeRate = 83.0; // Default USD to INR rate
  int currentImageIndex = 0; // Track current image in carousel
  late PageController pageController; // Controller for PageView

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    fetchData();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    await Future.wait([fetchProduct(), fetchExchangeRate()]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchProduct() async {
    product = await ApiService.getProductDetail(widget.productId);
  }

  Future<void> fetchExchangeRate() async {
    exchangeRate = await ApiService.getExchangeRate();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B11),
        appBar: AppBar(backgroundColor: Colors.black87),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1B11),
        appBar: AppBar(backgroundColor: Colors.black87),
        body: const Center(
          child: Text(
            'Product not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Prepare image list - use images array if available, fallback to imageUrl
    final imageList = product!.images.isNotEmpty
        ? product!.images
        : [if (product!.imageUrl != null) product!.imageUrl!];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B11),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (imageList.isNotEmpty)
              Column(
                children: [
                  // Main Image PageView
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: imageList.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageList[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              color: Colors.grey.withOpacity(0.2),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.white38,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Thumbnail ListView
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageList.length,
                        itemBuilder: (context, index) {
                          final isSelected = currentImageIndex == index;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: GestureDetector(
                              onTap: () {
                                pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.lightGreenAccent,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageList[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 30,
                                          color: Colors.white38,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            else
              // Fallback when no images available
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.withOpacity(0.2),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 80,
                  color: Colors.white38,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating and Category
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        product!.rating.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightGreenAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product!.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    '₹${(product!.price * exchangeRate).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.lightGreenAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Status
                  Row(
                    children: [
                      Icon(
                        product!.isInStock ? Icons.check_circle : Icons.cancel,
                        color: product!.isInStock ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product!.isInStock
                            ? 'In Stock (${product!.stock} units)'
                            : 'Out of Stock',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product!.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: product!.isInStock
                          ? () async {
                              bool success = await ApiService.addToCart(
                                userId: widget.userData['id'],
                                productId: product!.id,
                              );

                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to add to cart'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(
                        product!.isInStock ? 'ADD TO CART' : 'OUT OF STOCK',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();

  final _wishlistChangeController = StreamController<WishlistChangeEvent>.broadcast();

  WishlistService._internal();

  factory WishlistService() {
    return _instance;
  }

  Stream<WishlistChangeEvent> get wishlistChangeStream => _wishlistChangeController.stream;

  void notifyWishlistChange(WishlistChangeEvent event) {
    _wishlistChangeController.add(event);
  }

  void dispose() {
    _wishlistChangeController.close();
  }
}

class WishlistChangeEvent {
  final int productId;
  final bool isAdded; // true if added, false if removed

  WishlistChangeEvent({
    required this.productId,
    required this.isAdded,
  });
}

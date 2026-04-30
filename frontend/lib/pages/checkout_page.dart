// import 'package:flutter/material.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import '../services/api_service.dart';
// import 'dart:js' as js;

// const Color kBrandRed = Color(0xFFE4252A);
// const Color kTextDark = Color(0xFF1A1A1A);
// const Color kTextMuted = Color(0xFF6B6B6B);
// const Color kBackground = Colors.white;
// const Color kSurface = Color(0xFFF7F7F7);
// const Color kBorder = Color(0xFFEAEAEA);

// class CheckoutPage extends StatefulWidget {
//   final int userId;
//   final List<Map<String, dynamic>> selectedItems;
//   final bool promoApplied;
//   final double deliveryFee;
//   final double discountPercent;

//   const CheckoutPage({
//     super.key,
//     required this.userId,
//     required this.selectedItems,
//     required this.promoApplied,
//     required this.deliveryFee,
//     required this.discountPercent,
//   });

//   @override
//   State<CheckoutPage> createState() => _CheckoutPageState();
// }

// class _CheckoutPageState extends State<CheckoutPage> {
//   // ─── Razorpay ────────────────────────────────────────────────────────────────
//   late Razorpay _razorpay;

//   static const String _razorpayKeyId = 'rzp_test_Sjf5R4l0R8Ah9G';

//   // ─── Address ─────────────────────────────────────────────────────────────────
//   List<Map<String, dynamic>> _savedAddresses = [];
//   bool _isLoadingAddresses = true;
//   int? _selectedAddressId;
//   bool _showAddressForm = false;

//   final _formKey = GlobalKey<FormState>();
//   final _firstNameController = TextEditingController();
//   final _lastNameController = TextEditingController();
//   final _addressLine1Controller = TextEditingController();
//   final _addressLine2Controller = TextEditingController();
//   final _cityController = TextEditingController();
//   final _postalCodeController = TextEditingController();

//   static const List<String> _countries = ['India', 'United States', 'Canada'];
//   static const Map<String, List<String>> _statesByCountry = {
//     'India': ['Tamil Nadu', 'Karnataka', 'Kerala', 'Maharashtra', 'Delhi', 'Telangana'],
//     'United States': ['California', 'Texas', 'New York', 'Florida', 'Washington'],
//     'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
//   };
//   static const List<String> _addressTypes = ['home', 'office', 'other'];

//   String _selectedCountry = 'India';
//   String? _selectedState = 'Tamil Nadu';
//   String _selectedAddressType = 'home';
//   String _paymentMethod = 'upi';
//   bool _isPlacingOrder = false;
//   bool _isSavingAddress = false;

//   // ─── Lifecycle ───────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _initRazorpay();
//     _loadSavedAddresses();
//   }

//   void _initRazorpay() {
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   @override
//   void dispose() {
//     _razorpay.clear();
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _addressLine1Controller.dispose();
//     _addressLine2Controller.dispose();
//     _cityController.dispose();
//     _postalCodeController.dispose();
//     super.dispose();
//   }

//   // ─── Razorpay Handlers ───────────────────────────────────────────────────────

//   /// Called when Razorpay payment succeeds → now place the actual order
//   void _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     debugPrint('✅ Payment Success: ${response.paymentId}');

//     if (!mounted) return;

//     // Show payment success feedback
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Payment successful! ID: ${response.paymentId}'),
//         backgroundColor: const Color(0xFF1DB954),
//       ),
//     );

//     // Now actually place the order in your backend
//     await _submitOrderToBackend(paymentId: response.paymentId);
//   }

//   /// Called when Razorpay payment fails or user cancels
//   void _handlePaymentError(PaymentFailureResponse response) {
//     debugPrint('❌ Payment Error: ${response.code} | ${response.message}');

//     if (!mounted) return;

//     final isUserCancelled = response.code == Razorpay.PAYMENT_CANCELLED;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           isUserCancelled
//               ? 'Payment cancelled. Order was not placed.'
//               : 'Payment failed: ${response.message ?? "Unknown error"}',
//         ),
//         backgroundColor: isUserCancelled ? Colors.orange : Colors.red,
//       ),
//     );

//     setState(() => _isPlacingOrder = false);
//   }

//   /// Called when user selects an external wallet (PhonePe, etc.)
//   void _handleExternalWallet(ExternalWalletResponse response) {
//     debugPrint('👛 External Wallet: ${response.walletName}');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('External wallet: ${response.walletName}')),
//     );
//   }

//   // ─── Payment Flow ────────────────────────────────────────────────────────────

//   /// Opens Razorpay checkout for UPI/card payment
//   void _openRazorpayCheckout() {
//     // Razorpay expects amount in PAISE (₹1 = 100 paise)
//     final int amountInPaise = (total * 100).round();

//     final options = <String, dynamic>{
//       'key': 'rzp_test_Sjf5R4l0R8Ah9G',
//       'amount': amountInPaise,
//       'name': 'Your App Name',           // 🔧 Change to your app/brand name
//       'description': 'Order Payment',
//       'currency': 'INR',
//       'prefill': {
//         'contact': '9999999999',         // 🔧 Optionally pass user's phone
//         'email': 'user@example.com',     // 🔧 Optionally pass user's email
//       },
//       'theme': {
//         'color': '#E4252A',              // Matches your kBrandRed
//       },
//       'external': {
//         'wallets': ['paytm', 'phonepe'], // Optional: allow external wallets
//       },
//     };

//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       debugPrint('Razorpay open error: $e');
//       setState(() => _isPlacingOrder = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Could not open payment gateway: $e')),
//       );
//     }
//   }

//   /// Submits the order to your backend after successful payment
//   Future<void> _submitOrderToBackend({String? paymentId}) async {
//     setState(() => _isPlacingOrder = true);

//     final result = await ApiService.checkoutCart(
//       userId: widget.userId,
//       productIds: widget.selectedItems
//           .map<int>((item) => item['product_id'] as int)
//           .toList(),
//       addressId: _selectedAddressId,
//       paymentMethod: _paymentMethod,
//       // Optionally pass paymentId to your backend for verification:
//       // paymentId: paymentId,
//     );

//     if (!mounted) return;

//     setState(() => _isPlacingOrder = false);

//     if (result['success'] == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('🎉 Order placed successfully!'),
//           backgroundColor: Color(0xFF1DB954),
//         ),
//       );
//       Navigator.pop(context, true);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error']?.toString() ?? 'Failed to place order'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // ─── Place Order Entry Point ──────────────────────────────────────────────────

//   Future<void> _placeOrder() async {
//     // 1. Validate address selection
//     if (_selectedAddressId == null && !_showAddressForm) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a delivery address')),
//       );
//       return;
//     }

//     // 2. If user is filling a new address form, save it first
//     if (_showAddressForm) {
//       await _saveNewAddress();
//       if (_selectedAddressId == null) return; // save failed
//     }

//     setState(() => _isPlacingOrder = true);

//     // 3. Route based on payment method
//     if (_paymentMethod == 'cod') {
//       // Cash on delivery → skip Razorpay, go straight to backend
//       await _submitOrderToBackend();
//     } else {
//       // UPI / card → open Razorpay
//       // isPlacingOrder stays true; will be reset in success/error handler
//       _openRazorpayCheckout();
//     }
//   }

//   // ─── Address Logic ───────────────────────────────────────────────────────────

//   Future<void> _loadSavedAddresses() async {
//     setState(() => _isLoadingAddresses = true);
//     final result = await ApiService.getUserAddresses(widget.userId);
//     if (!mounted) return;
//     setState(() {
//       _isLoadingAddresses = false;
//       if (result['addresses'] != null) {
//         _savedAddresses = List<Map<String, dynamic>>.from(result['addresses']);
//         if (_savedAddresses.isNotEmpty) {
//           final defaultAddress = _savedAddresses.firstWhere(
//             (addr) => addr['is_default'] == true,
//             orElse: () => _savedAddresses.first,
//           );
//           _selectedAddressId = defaultAddress['id'];
//         } else {
//           _showAddressForm = true;
//         }
//       }
//     });
//   }

//   List<String> get _stateOptions =>
//       _statesByCountry[_selectedCountry] ?? const <String>[];

//   double get subtotal => widget.selectedItems.fold(
//         0.0,
//         (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
//       );

//   double get total =>
//       subtotal + widget.deliveryFee - (subtotal * widget.discountPercent / 100);

//   Future<void> _saveNewAddress() async {
//     if (!_formKey.currentState!.validate() || _selectedState == null) {
//       if (_selectedState == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select a state / province')),
//         );
//       }
//       return;
//     }

//     setState(() => _isSavingAddress = true);

//     final result = await ApiService.createAddress(
//       userId: widget.userId,
//       addressData: {
//         'address_type': _selectedAddressType,
//         'first_name': _firstNameController.text.trim(),
//         'last_name': _lastNameController.text.trim(),
//         'address_line_1': _addressLine1Controller.text.trim(),
//         'address_line_2': _addressLine2Controller.text.trim(),
//         'city': _cityController.text.trim(),
//         'state': _selectedState,
//         'postal_code': _postalCodeController.text.trim(),
//         'country': _selectedCountry,
//         'is_default': _savedAddresses.isEmpty,
//       },
//     );

//     if (!mounted) return;
//     setState(() => _isSavingAddress = false);

//     if (result['success'] == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Address saved successfully'),
//           backgroundColor: Color(0xFF1DB954),
//         ),
//       );
//       _clearForm();
//       await _loadSavedAddresses();
//       setState(() => _showAddressForm = false);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['error']?.toString() ?? 'Failed to save address'),
//         ),
//       );
//     }
//   }

//   void _clearForm() {
//     _firstNameController.clear();
//     _lastNameController.clear();
//     _addressLine1Controller.clear();
//     _addressLine2Controller.clear();
//     _cityController.clear();
//     _postalCodeController.clear();
//     setState(() {
//       _selectedCountry = 'India';
//       _selectedState = 'Tamil Nadu';
//       _selectedAddressType = 'home';
//     });
//   }

//   Future<void> _confirmDeleteAddress(int addressId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Address'),
//         content: const Text('Are you sure you want to delete this address?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       final result = await ApiService.deleteAddress(
//         addressId: addressId,
//         userId: widget.userId,
//       );
//       if (!mounted) return;
//       if (result['success'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Address deleted'),
//             backgroundColor: Color(0xFF1DB954),
//           ),
//         );
//         await _loadSavedAddresses();
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result['error']?.toString() ?? 'Failed to delete address'),
//           ),
//         );
//       }
//     }
//   }

//   // ─── Build ───────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//         title: const Text(
//           'Checkout',
//           style: TextStyle(
//             color: kBrandRed,
//             fontSize: 21,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   _buildAddressSection(),
//                   const SizedBox(height: 16),
//                   _buildSection(
//                     title: 'Order Summary',
//                     child: Column(
//                       children: [
//                         for (final item in widget.selectedItems) ...[
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Container(
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   color: kSurface,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: Image.network(
//                                     item['image'],
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (_, __, ___) => const Icon(
//                                       Icons.image_outlined,
//                                       color: Colors.grey,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       item['product_name'],
//                                       style: const TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w700,
//                                         color: kTextDark,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       'Qty: ${item['quantity']}',
//                                       style: const TextStyle(
//                                         color: kTextMuted,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Text(
//                                 '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w700,
//                                   color: kTextDark,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                         ],
//                         const Divider(color: kBorder),
//                         _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
//                         _summaryRow('Delivery Fee', '₹${widget.deliveryFee.toStringAsFixed(2)}'),
//                         if (widget.promoApplied)
//                           _summaryRow('Discount', '${widget.discountPercent.toInt()}%'),
//                         const SizedBox(height: 6),
//                         _summaryRow('Total', '₹${total.toStringAsFixed(2)}', emphasize: true),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSection(
//                     title: 'Payment Details',
//                     child: Column(
//                       children: [
//                         RadioListTile<String>(
//                           value: 'upi',
//                           groupValue: _paymentMethod,
//                           activeColor: kBrandRed,
//                           contentPadding: EdgeInsets.zero,
//                           title: const Text('UPI / Card'),
//                           subtitle: const Text('Pay securely via Razorpay'),
//                           secondary: Image.network(
//                             'https://razorpay.com/favicon.png',
//                             width: 28,
//                             errorBuilder: (_, __, ___) => const Icon(Icons.payment),
//                           ),
//                           onChanged: (value) {
//                             if (value != null) setState(() => _paymentMethod = value);
//                           },
//                         ),
//                         const Divider(color: kBorder),
//                         RadioListTile<String>(
//                           value: 'cod',
//                           groupValue: _paymentMethod,
//                           activeColor: kBrandRed,
//                           contentPadding: EdgeInsets.zero,
//                           title: const Text('Cash on Delivery'),
//                           subtitle: const Text('Pay when the order arrives'),
//                           secondary: const Icon(Icons.money, color: Colors.green, size: 28),
//                           onChanged: (value) {
//                             if (value != null) setState(() => _paymentMethod = value);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // ── Place Order Button ──────────────────────────────────────────
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: _isPlacingOrder ? null : _placeOrder,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kBrandRed,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: _isPlacingOrder
//                       ? const SizedBox(
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.4,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               _paymentMethod == 'cod'
//                                   ? Icons.money
//                                   : Icons.lock_outline,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               _paymentMethod == 'cod'
//                                   ? 'Place Order ₹${total.toStringAsFixed(2)}'
//                                   : 'Pay ₹${total.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─── Address Widgets ─────────────────────────────────────────────────────────

//   Widget _buildAddressSection() {
//     return _buildSection(
//       title: 'Delivery Address',
//       child: _isLoadingAddresses
//           ? const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(20),
//                 child: CircularProgressIndicator(color: kBrandRed),
//               ),
//             )
//           : Column(
//               children: [
//                 if (_savedAddresses.isNotEmpty && !_showAddressForm)
//                   ..._savedAddresses.map((address) => _buildAddressCard(address)),
//                 if (!_showAddressForm)
//                   InkWell(
//                     onTap: () {
//                       setState(() {
//                         _showAddressForm = true;
//                         _selectedAddressId = null;
//                       });
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: kBorder, width: 1.5),
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: Row(
//                         children: const [
//                           Icon(Icons.add_circle_outline, color: kBrandRed, size: 24),
//                           SizedBox(width: 12),
//                           Text(
//                             'Add New Address',
//                             style: TextStyle(
//                               color: kBrandRed,
//                               fontSize: 15,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 if (_showAddressForm) _buildAddressForm(),
//               ],
//             ),
//     );
//   }

//   Widget _buildAddressCard(Map<String, dynamic> address) {
//     final isSelected = _selectedAddressId == address['id'];
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: isSelected ? kBrandRed : kBorder,
//           width: isSelected ? 2 : 1,
//         ),
//         borderRadius: BorderRadius.circular(14),
//         color: isSelected ? kBrandRed.withOpacity(0.05) : Colors.white,
//       ),
//       child: InkWell(
//         onTap: () => setState(() {
//           _selectedAddressId = address['id'];
//           _showAddressForm = false;
//         }),
//         borderRadius: BorderRadius.circular(14),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Radio<int>(
//                 value: address['id'],
//                 groupValue: _selectedAddressId,
//                 activeColor: kBrandRed,
//                 onChanged: (value) => setState(() {
//                   _selectedAddressId = value;
//                   _showAddressForm = false;
//                 }),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         _tag(address['address_type'].toString().toUpperCase(), kBrandRed),
//                         if (address['is_default'] == true) ...[
//                           const SizedBox(width: 8),
//                           _tag('DEFAULT', Colors.green),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${address['first_name']} ${address['last_name']}',
//                       style: const TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         color: kTextDark,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(address['address_line_1'],
//                         style: const TextStyle(fontSize: 13, color: kTextMuted)),
//                     if (address['address_line_2']?.isNotEmpty == true)
//                       Text(address['address_line_2'],
//                           style: const TextStyle(fontSize: 13, color: kTextMuted)),
//                     Text(
//                         '${address['city']}, ${address['state']} ${address['postal_code']}',
//                         style: const TextStyle(fontSize: 13, color: kTextMuted)),
//                     Text(address['country'],
//                         style: const TextStyle(fontSize: 13, color: kTextMuted)),
//                   ],
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete_outline, color: Colors.red),
//                 onPressed: () => _confirmDeleteAddress(address['id']),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _tag(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildAddressForm() {
//     return Form(
//       key: _formKey,
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('New Address',
//                   style: TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
//               if (_savedAddresses.isNotEmpty)
//                 TextButton(
//                   onPressed: () => setState(() {
//                     _showAddressForm = false;
//                     _clearForm();
//                     if (_savedAddresses.isNotEmpty) {
//                       _selectedAddressId = _savedAddresses.first['id'];
//                     }
//                   }),
//                   child: const Text('Cancel'),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildDropdownField<String>(
//             value: _selectedAddressType,
//             label: 'Address Type',
//             items: _addressTypes,
//             onChanged: (value) {
//               if (value != null) setState(() => _selectedAddressType = value);
//             },
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextField(
//                   controller: _firstNameController,
//                   label: 'First Name',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _lastNameController,
//                   label: 'Last Name',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _addressLine1Controller,
//             label: 'Address Line 1',
//             hint: 'Street address, P.O. box',
//             validator: _requiredValidator,
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _addressLine2Controller,
//             label: 'Address Line 2',
//             hint: 'Apartment, suite, unit',
//           ),
//           const SizedBox(height: 12),
//           _buildTextField(
//             controller: _cityController,
//             label: 'City',
//             hint: 'Required',
//             validator: _requiredValidator,
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildDropdownField<String>(
//                   value: _selectedState,
//                   label: 'State / Province',
//                   items: _stateOptions,
//                   onChanged: (value) => setState(() => _selectedState = value),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _postalCodeController,
//                   label: 'Postal Code',
//                   hint: 'Required',
//                   validator: _requiredValidator,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildDropdownField<String>(
//             value: _selectedCountry,
//             label: 'Country',
//             items: _countries,
//             onChanged: (value) {
//               if (value != null) {
//                 setState(() {
//                   _selectedCountry = value;
//                   final nextStates = _statesByCountry[_selectedCountry] ?? const [];
//                   _selectedState = nextStates.isNotEmpty ? nextStates.first : null;
//                 });
//               }
//             },
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: ElevatedButton(
//               onPressed: _isSavingAddress ? null : _saveNewAddress,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kBrandRed,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//               child: _isSavingAddress
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: Colors.white))
//                   : const Text('Save Address',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── Reusable Widgets ────────────────────────────────────────────────────────

//   Widget _buildSection({required String title, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(
//                   color: kTextDark, fontSize: 18, fontWeight: FontWeight.w700)),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label,
//             style: const TextStyle(
//                 color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           validator: validator,
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: kSurface,
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: const BorderSide(color: kBorder)),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: const BorderSide(color: kBrandRed, width: 1.3)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField<T>({
//     required T? value,
//     required String label,
//     required List<T> items,
//     required ValueChanged<T?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label,
//             style: const TextStyle(
//                 color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<T>(
//           value: value,
//           items: items
//               .map((item) => DropdownMenuItem<T>(
//                   value: item, child: Text(item.toString())))
//               .toList(),
//           onChanged: onChanged,
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: kSurface,
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: BorderSide.none),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: const BorderSide(color: kBorder)),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(14),
//                 borderSide: const BorderSide(color: kBrandRed, width: 1.3)),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _summaryRow(String label, String value, {bool emphasize = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   color: emphasize ? kTextDark : kTextMuted,
//                   fontSize: emphasize ? 15 : 14,
//                   fontWeight:
//                       emphasize ? FontWeight.w700 : FontWeight.w500)),
//           Text(value,
//               style: TextStyle(
//                   color: kTextDark,
//                   fontSize: emphasize ? 16 : 14,
//                   fontWeight:
//                       emphasize ? FontWeight.w800 : FontWeight.w600)),
//         ],
//       ),
//     );
//   }

//   String? _requiredValidator(String? value) {
//     if (value == null || value.trim().isEmpty) return 'This field is required';
//     return null;
//   }
// }



// checkout_page.dart
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kSurface = Color(0xFFF7F7F7);
const Color kBorder = Color(0xFFEAEAEA);

class CheckoutPage extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> selectedItems;
  final bool promoApplied;
  final double deliveryFee;
  final double discountPercent;

  const CheckoutPage({
    super.key,
    required this.userId,
    required this.selectedItems,
    required this.promoApplied,
    required this.deliveryFee,
    required this.discountPercent,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // 🔑 Only Key ID here — Key Secret goes on your backend ONLY
  static const String _razorpayKeyId = 'rzp_test_Sjf5R4l0R8Ah9G';

  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingAddresses = true;
  int? _selectedAddressId;
  bool _showAddressForm = false;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  static const List<String> _countries = ['India', 'United States', 'Canada'];
  static const Map<String, List<String>> _statesByCountry = {
    'India': ['Tamil Nadu', 'Karnataka', 'Kerala', 'Maharashtra', 'Delhi', 'Telangana'],
    'United States': ['California', 'Texas', 'New York', 'Florida', 'Washington'],
    'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
  };
  static const List<String> _addressTypes = ['home', 'office', 'other'];

  String _selectedCountry = 'India';
  String? _selectedState = 'Tamil Nadu';
  String _selectedAddressType = 'home';
  String _paymentMethod = 'upi';
  bool _isPlacingOrder = false;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  // ─── Razorpay Web JS ─────────────────────────────────────────────────────────

  void _openRazorpayCheckout() {
    final int amountInPaise = (total * 100).round();

    final options = js.JsObject.jsify({
      'key': _razorpayKeyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'Your App Name',       // 🔧 Change to your brand name
      'description': 'Order Payment',
      'theme': {'color': '#E4252A'},
      'prefill': {
        'contact': '9999999999',     // 🔧 Pass real user phone if available
        'email': 'user@example.com', // 🔧 Pass real user email if available
      },
      // ✅ Called when payment succeeds
      'handler': js.allowInterop((dynamic response) {
        final paymentId = response['razorpay_payment_id']?.toString() ?? '';
        _onPaymentSuccess(paymentId);
      }),
      // ✅ Called when user closes/cancels the modal
      'modal': {
        'ondismiss': js.allowInterop(() {
          _onPaymentCancelled();
        }),
      },
    });

    try {
      final razorpayInstance =
          js.JsObject(js.context['Razorpay'] as js.JsFunction, [options]);
      razorpayInstance.callMethod('open');
    } catch (e) {
      debugPrint('Razorpay open error: $e');
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open payment gateway: $e')),
        );
      }
    }
  }

  void _onPaymentSuccess(String paymentId) {
    debugPrint('✅ Razorpay Payment Success: $paymentId');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment successful! ID: $paymentId'),
        backgroundColor: const Color(0xFF1DB954),
      ),
    );
    _submitOrderToBackend(paymentId: paymentId);
  }

  void _onPaymentCancelled() {
    debugPrint('❌ Razorpay Payment Cancelled');
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled. Order was not placed.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ─── Submit Order to Backend ─────────────────────────────────────────────────

  Future<void> _submitOrderToBackend({String? paymentId}) async {
    setState(() => _isPlacingOrder = true);

    final result = await ApiService.checkoutCart(
      userId: widget.userId,
      productIds: widget.selectedItems
          .map<int>((item) => item['product_id'] as int)
          .toList(),
      addressId: _selectedAddressId,
      paymentMethod: _paymentMethod,
      // Pass paymentId to backend for verification if needed:
      // paymentId: paymentId,
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Order placed successfully!'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Failed to place order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Place Order Entry Point ──────────────────────────────────────────────────

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null && !_showAddressForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (_showAddressForm) {
      await _saveNewAddress();
      if (_selectedAddressId == null) return;
    }

    setState(() => _isPlacingOrder = true);

    if (_paymentMethod == 'cod') {
      // Cash on Delivery → skip Razorpay, go straight to backend
      await _submitOrderToBackend();
    } else {
      // UPI/Card → open Razorpay Web checkout
      _openRazorpayCheckout();
      // Note: _isPlacingOrder stays true until handler fires
    }
  }

  // ─── Address ─────────────────────────────────────────────────────────────────

  Future<void> _loadSavedAddresses() async {
    setState(() => _isLoadingAddresses = true);
    final result = await ApiService.getUserAddresses(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoadingAddresses = false;
      if (result['addresses'] != null) {
        _savedAddresses = List<Map<String, dynamic>>.from(result['addresses']);
        if (_savedAddresses.isNotEmpty) {
          final defaultAddress = _savedAddresses.firstWhere(
            (addr) => addr['is_default'] == true,
            orElse: () => _savedAddresses.first,
          );
          _selectedAddressId = defaultAddress['id'];
        } else {
          _showAddressForm = true;
        }
      }
    });
  }

  List<String> get _stateOptions =>
      _statesByCountry[_selectedCountry] ?? const <String>[];

  double get subtotal => widget.selectedItems.fold(
        0.0,
        (sum, item) =>
            sum + ((item['price'] as num) * (item['quantity'] as num)),
      );

  double get total =>
      subtotal +
      widget.deliveryFee -
      (subtotal * widget.discountPercent / 100);

  Future<void> _saveNewAddress() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state / province')),
        );
      }
      return;
    }
    setState(() => _isSavingAddress = true);
    final result = await ApiService.createAddress(
      userId: widget.userId,
      addressData: {
        'address_type': _selectedAddressType,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'address_line_1': _addressLine1Controller.text.trim(),
        'address_line_2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'postal_code': _postalCodeController.text.trim(),
        'country': _selectedCountry,
        'is_default': _savedAddresses.isEmpty,
      },
    );
    if (!mounted) return;
    setState(() => _isSavingAddress = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
      _clearForm();
      await _loadSavedAddresses();
      setState(() => _showAddressForm = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              result['error']?.toString() ?? 'Failed to save address'),
        ),
      );
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _postalCodeController.clear();
    setState(() {
      _selectedCountry = 'India';
      _selectedState = 'Tamil Nadu';
      _selectedAddressType = 'home';
    });
  }

  Future<void> _confirmDeleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content:
            const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.deleteAddress(
        addressId: addressId,
        userId: widget.userId,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
        await _loadSavedAddresses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['error']?.toString() ?? 'Failed to delete address'),
          ),
        );
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: kBrandRed,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Order Summary',
                    child: Column(
                      children: [
                        for (final item in widget.selectedItems) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product_name'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: kTextDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item['quantity']}',
                                      style: const TextStyle(
                                        color: kTextMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kTextDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Divider(color: kBorder),
                        _summaryRow('Subtotal',
                            '₹${subtotal.toStringAsFixed(2)}'),
                        _summaryRow('Delivery Fee',
                            '₹${widget.deliveryFee.toStringAsFixed(2)}'),
                        if (widget.promoApplied)
                          _summaryRow('Discount',
                              '${widget.discountPercent.toInt()}%'),
                        const SizedBox(height: 6),
                        _summaryRow(
                          'Total',
                          '₹${total.toStringAsFixed(2)}',
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Payment Details',
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'upi',
                          groupValue: _paymentMethod,
                          activeColor: kBrandRed,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('UPI / Card'),
                          subtitle: const Text(
                              'Pay securely via Razorpay'),
                          secondary: const Icon(Icons.payment,
                              color: kBrandRed),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          },
                        ),
                        const Divider(color: kBorder),
                        RadioListTile<String>(
                          value: 'cod',
                          groupValue: _paymentMethod,
                          activeColor: kBrandRed,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Cash on Delivery'),
                          subtitle:
                              const Text('Pay when the order arrives'),
                          secondary: const Icon(Icons.money,
                              color: Colors.green),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _paymentMethod = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _paymentMethod == 'cod'
                                  ? Icons.money
                                  : Icons.lock_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _paymentMethod == 'cod'
                                  ? 'Place Order ₹${total.toStringAsFixed(2)}'
                                  : 'Pay ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return _buildSection(
      title: 'Delivery Address',
      child: _isLoadingAddresses
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: kBrandRed),
              ),
            )
          : Column(
              children: [
                if (_savedAddresses.isNotEmpty && !_showAddressForm)
                  ..._savedAddresses
                      .map((address) => _buildAddressCard(address)),
                if (!_showAddressForm)
                  InkWell(
                    onTap: () => setState(() {
                      _showAddressForm = true;
                      _selectedAddressId = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder, width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: kBrandRed, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Add New Address',
                            style: TextStyle(
                              color: kBrandRed,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showAddressForm) _buildAddressForm(),
              ],
            ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isSelected = _selectedAddressId == address['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? kBrandRed : kBorder,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        color: isSelected ? kBrandRed.withOpacity(0.05) : Colors.white,
      ),
      child: InkWell(
        onTap: () => setState(() {
          _selectedAddressId = address['id'];
          _showAddressForm = false;
        }),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<int>(
                value: address['id'],
                groupValue: _selectedAddressId,
                activeColor: kBrandRed,
                onChanged: (value) => setState(() {
                  _selectedAddressId = value;
                  _showAddressForm = false;
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tag(
                          address['address_type']
                              .toString()
                              .toUpperCase(),
                          kBrandRed,
                        ),
                        if (address['is_default'] == true) ...[
                          const SizedBox(width: 8),
                          _tag('DEFAULT', Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${address['first_name']} ${address['last_name']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(address['address_line_1'],
                        style: const TextStyle(
                            fontSize: 13, color: kTextMuted)),
                    if (address['address_line_2']?.isNotEmpty == true)
                      Text(address['address_line_2'],
                          style: const TextStyle(
                              fontSize: 13, color: kTextMuted)),
                    Text(
                      '${address['city']}, ${address['state']} ${address['postal_code']}',
                      style: const TextStyle(
                          fontSize: 13, color: kTextMuted),
                    ),
                    Text(address['country'],
                        style: const TextStyle(
                            fontSize: 13, color: kTextMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () =>
                    _confirmDeleteAddress(address['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Address',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kTextDark)),
              if (_savedAddresses.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _showAddressForm = false;
                    _clearForm();
                    if (_savedAddresses.isNotEmpty) {
                      _selectedAddressId =
                          _savedAddresses.first['id'];
                    }
                  }),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            value: _selectedAddressType,
            label: 'Address Type',
            items: _addressTypes,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedAddressType = value);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine1Controller,
            label: 'Address Line 1',
            hint: 'Street address, P.O. box',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine2Controller,
            label: 'Address Line 2',
            hint: 'Apartment, suite, unit',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Required',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  value: _selectedState,
                  label: 'State / Province',
                  items: _stateOptions,
                  onChanged: (value) =>
                      setState(() => _selectedState = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  hint: 'Required',
                  validator: _requiredValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdownField<String>(
            value: _selectedCountry,
            label: 'Country',
            items: _countries,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCountry = value;
                  final nextStates =
                      _statesByCountry[_selectedCountry] ?? const [];
                  _selectedState =
                      nextStates.isNotEmpty ? nextStates.first : null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingAddress ? null : _saveNewAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandRed,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSavingAddress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Address',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: kTextDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: kBrandRed, width: 1.3)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem<T>(
                  value: item, child: Text(item.toString())))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: kBrandRed, width: 1.3)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: emphasize ? kTextDark : kTextMuted,
                  fontSize: emphasize ? 15 : 14,
                  fontWeight: emphasize
                      ? FontWeight.w700
                      : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: kTextDark,
                  fontSize: emphasize ? 16 : 14,
                  fontWeight: emphasize
                      ? FontWeight.w800
                      : FontWeight.w600)),
        ],
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
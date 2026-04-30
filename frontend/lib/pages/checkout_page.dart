import 'package:flutter/material.dart';

import '../services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kBackground = Colors.white;
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
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  static const List<String> _countries = ['India', 'United States', 'Canada'];
  static const Map<String, List<String>> _statesByCountry = {
    'India': [
      'Tamil Nadu',
      'Karnataka',
      'Kerala',
      'Maharashtra',
      'Delhi',
      'Telangana',
    ],
    'United States': [
      'California',
      'Texas',
      'New York',
      'Florida',
      'Washington',
    ],
    'Canada': ['Ontario', 'British Columbia', 'Quebec', 'Alberta'],
  };

  String _selectedCountry = 'India';
  String? _selectedState = 'Tamil Nadu';
  String _paymentMethod = 'upi';
  bool _isPlacingOrder = false;

  List<String> get _stateOptions =>
      _statesByCountry[_selectedCountry] ?? const <String>[];

  double get subtotal => widget.selectedItems.fold(
    0.0,
    (sum, item) => sum + ((item['price'] as num) * (item['quantity'] as num)),
  );

  double get total =>
      subtotal + widget.deliveryFee - (subtotal * widget.discountPercent / 100);

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate() || _selectedState == null) {
      if (_selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a state / province')),
        );
      }
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final result = await ApiService.checkoutCart(
      userId: widget.userId,
      productIds: widget.selectedItems
          .map<int>((item) => item['product_id'] as int)
          .toList(),
      shippingAddress: {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'address_line_1': _addressLine1Controller.text.trim(),
        'address_line_2': _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'postal_code': _postalCodeController.text.trim(),
        'country': _selectedCountry,
      },
      paymentMethod: _paymentMethod,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPlacingOrder = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['error']?.toString() ?? 'Failed to place order'),
      ),
    );
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection(
                      title: 'Shipping Address',
                      child: Column(
                        children: [
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
                            hint: 'Street address, P.O. box, company name',
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _addressLine2Controller,
                            label: 'Address Line 2',
                            hint: 'Apartment, suite, unit, building, floor',
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
                                  label: 'State / Province / Region',
                                  items: _stateOptions,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedState = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _postalCodeController,
                                  label: 'ZIP / Postal Code',
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
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedCountry = value;
                                final nextStates =
                                    _statesByCountry[_selectedCountry] ??
                                    const [];
                                _selectedState = nextStates.isNotEmpty
                                    ? nextStates.first
                                    : null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
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
                                      errorBuilder: (_, _, _) => const Icon(
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
                          _summaryRow(
                            'Subtotal',
                            '₹${subtotal.toStringAsFixed(2)}',
                          ),
                          _summaryRow(
                            'Delivery Fee',
                            '₹${widget.deliveryFee.toStringAsFixed(2)}',
                          ),
                          if (widget.promoApplied)
                            _summaryRow(
                              'Discount',
                              '${widget.discountPercent.toInt()}%',
                            ),
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
                            title: const Text('UPI'),
                            subtitle: const Text('Pay using any UPI app'),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _paymentMethod = value;
                              });
                            },
                          ),
                          const Divider(color: kBorder),
                          RadioListTile<String>(
                            value: 'cod',
                            groupValue: _paymentMethod,
                            activeColor: kBrandRed,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Cash on Delivery'),
                            subtitle: const Text('Pay when the order arrives'),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _paymentMethod = value;
                              });
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        : Text(
                            'Place Order ₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          Text(
            title,
            style: const TextStyle(
              color: kTextDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
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
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBrandRed, width: 1.3),
            ),
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
        Text(
          label,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kBrandRed, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: emphasize ? kTextDark : kTextMuted,
              fontSize: emphasize ? 15 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: kTextDark,
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
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

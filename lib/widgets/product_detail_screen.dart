import 'package:farmer_consumer_marketplace/widgets/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';
import 'package:farmer_consumer_marketplace/widgets/quantity_selector.dart';
import 'package:farmer_consumer_marketplace/widgets/price_chart.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Map<String, dynamic> _product;
  int _selectedQuantity = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _priceHistory = [];
  bool _showPriceHistory = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchProductDetails();
    _fetchPriceHistory();
  }

  Future<void> _fetchProductDetails() async {
    try {
      if (widget.product['id'] != null) {
        final productDetails = await _firebaseService.getProductDetails(widget.product['id']);
        if (productDetails != null) {
          setState(() {
            _product = productDetails;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPriceHistory() async {
    try {
      final String productName = widget.product['name'] ?? '';
      if (productName.isNotEmpty) {
        final priceHistory = await _firebaseService.getProductPriceHistory(productName);
        setState(() {
          _priceHistory = priceHistory;
        });
      }
    } catch (e) {
      print('Error fetching price history: $e');
    }
  }

  void _updateQuantity(int quantity) {
    setState(() {
      _selectedQuantity = quantity;
    });
  }

  void _proceedToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          product: _product,
          quantity: _selectedQuantity,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Product Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final priceFormat = NumberFormat('#,##0.00');
    final price = _product['unitPrice'] != null
        ? double.parse(_product['unitPrice'].toString())
        : 0.0;
    final String formattedPrice = '₹${priceFormat.format(price)}';
    final String unit = _product['unit'] ?? 'kg';
    final double totalPrice = price * _selectedQuantity;
    final String formattedTotalPrice = '₹${priceFormat.format(totalPrice)}';
    final int availableQuantity = _product['quantity'] != null
        ? int.parse(_product['quantity'].toString())
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              setState(() {
                _showPriceHistory = !_showPriceHistory;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name and category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _product['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _product['category'] ?? 'Uncategorized',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 1),

                    // Price
                    Text(
                      '$formattedPrice/$unit',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Harvest date
                    if (_product['harvestDate'] != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'Harvested: ${_product['harvestDate']}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: 8),

                    // Farmer info
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sold by',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _product['farmerName'] ?? 'Unknown Farmer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _product['farmerLocation'] ?? 'Unknown Location',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Price history chart
                    if (_showPriceHistory)
                      _priceHistory.isNotEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: 200,
                                  child: PriceChart(priceHistory: _priceHistory),
                                ),
                                SizedBox(height: 16),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Price history not available'),
                              ),
                            ),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      _product['description'] ?? 'No description available',
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar with quantity selector and buy button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity selector
                Expanded(
                  child: QuantitySelector(
                    initialValue: _selectedQuantity,
                    minValue: 1,
                    maxValue: availableQuantity,
                    onChanged: _updateQuantity,
                  ),
                ),

                SizedBox(width: 16),

                // Buy button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total: $formattedTotalPrice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: availableQuantity > 0 ? _proceedToCheckout : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          minimumSize: Size(double.infinity, 45),
                        ),
                        child: Text(
                          availableQuantity > 0 ? 'Buy Now' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

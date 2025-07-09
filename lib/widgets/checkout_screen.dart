import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';
import 'package:farmer_consumer_marketplace/widgets/loading_button.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final String userId;

  const CheckoutScreen({
    Key? key,
    required this.product,
    required this.quantity,
    required this.userId,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  
  String _selectedPaymentMethod = 'COD';
  bool _isLoading = false;
  bool _isLoadingUserData = true;
  String _fullName = '';
  String _phoneNumber = '';
  String _defaultAddress = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    try {
      // Get current user data
      final userData = await _firebaseService.firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userData.exists) {
        setState(() {
          _fullName = userData.data()?['name'] ?? '';
          _phoneNumber = userData.data()?['phoneNumber'] ?? '';
          _defaultAddress = userData.data()?['location'] ?? '';
          
          // Pre-fill the address field
          _addressController.text = _defaultAddress;
          
          _isLoadingUserData = false;
        });
      } else {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate total amount
      final unitPrice = widget.product['unitPrice'] != null
          ? double.parse(widget.product['unitPrice'].toString())
          : 0.0;
      
      final totalAmount = unitPrice * widget.quantity;
      
      final success = await _firebaseService.placeOrder(
        userId: widget.userId,
        productId: widget.product['id'],
        farmerId: widget.product['farmerId'],
        productName: widget.product['name'],
        quantity: widget.quantity,
        unit: widget.product['unit'] ?? 'kg',
        unitPrice: unitPrice,
        totalAmount: totalAmount,
        deliveryAddress: _addressController.text,
        paymentMethod: _selectedPaymentMethod,
      );
      
      if (success) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Pop back to consumer dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total amount
    final unitPrice = widget.product['unitPrice'] != null
        ? double.parse(widget.product['unitPrice'].toString())
        : 0.0;
    
    final totalAmount = unitPrice * widget.quantity;
    
    // Format currency
    final priceFormat = NumberFormat('#,##0.00');
    final String formattedUnitPrice = '₹${priceFormat.format(unitPrice)}';
    final String formattedTotal = '₹${priceFormat.format(totalAmount)}';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: _isLoadingUserData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Product details
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product image
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[200],
                                  ),
                                  child: widget.product['imageUrl'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            widget.product['imageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey[400],
                                                size: 40,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.image,
                                          color: Colors.grey[400],
                                          size: 40,
                                        ),
                                ),
                                
                                SizedBox(width: 12),
                                
                                // Product info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.product['name'] ?? 'Unknown product',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      
                                      SizedBox(height: 4),
                                      
                                      Text(
                                        widget.product['category'] ?? 'Uncategorized',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      
                                      SizedBox(height: 8),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$formattedUnitPrice/${widget.product['unit'] ?? 'kg'}',
                                            style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          
                                          Text(
                                            'Qty: ${widget.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            Divider(),
                            
                            SizedBox(height: 8),
                            
                            // Price breakdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal'),
                                Text(formattedTotal),
                              ],
                            ),
                            
                            SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delivery'),
                                Text('₹0.00'),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            Divider(),
                            
                            SizedBox(height: 8),
                            
                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  formattedTotal,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Delivery details section
                    Text(
                      'Delivery Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Delivery form
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and phone
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _fullName,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Icon(Icons.phone, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(_phoneNumber),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Delivery address
                            TextFormField(
                              controller: _addressController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Delivery Address',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Icon(Icons.location_on),
                                ),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your delivery address';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Payment method section
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Payment methods
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Icon(Icons.money, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Cash on Delivery'),
                                ],
                              ),
                              value: 'COD',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                            
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('UPI Payment'),
                                ],
                              ),
                              value: 'UPI',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                            
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Icon(Icons.credit_card, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Card Payment'),
                                ],
                              ),
                              value: 'CARD',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMethod = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Place order button
                    LoadingButton(
                      isLoading: _isLoading,
                      onPressed: _placeOrder,
                      text: 'Place Order',
                      loadingText: 'Processing...',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
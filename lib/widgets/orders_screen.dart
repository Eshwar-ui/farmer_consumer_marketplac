import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  final String userId;

  const OrdersScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _firebaseService.getUserOrders(widget.userId);
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load orders. Please try again.'))
      );
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      final success = await _firebaseService.cancelOrder(orderId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order cancelled successfully'))
        );
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order. Please try again.'))
        );
      }
    } catch (e) {
      print('Error cancelling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.'))
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    switch (_tabController.index) {
      case 0: // All orders
        return _orders;
      case 1: // Pending orders
        return _orders.where((order) => order['status'] == 'pending').toList();
      case 2: // Completed orders
        return _orders.where((order) => 
          order['status'] == 'completed' || order['status'] == 'delivered').toList();
      default:
        return _orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {}); // Refresh to apply filter
          },
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final status = order['status'] ?? 'pending';
                      
                      // Format currency
                      final priceFormat = NumberFormat('#,##0.00');
                      final totalAmount = order['totalAmount'] != null
                          ? double.parse(order['totalAmount'].toString())
                          : 0.0;
                      
                      final String formattedTotal = '₹${priceFormat.format(totalAmount)}';
                      
                      // Format date
                      String formattedDate = order['orderDate'] ?? 'Unknown date';
                      try {
                        final DateTime orderDate = DateFormat('yyyy-MM-dd').parse(formattedDate);
                        formattedDate = DateFormat('dd MMM, yyyy').format(orderDate);
                      } catch (e) {
                        // Use the original string if parsing fails
                      }
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order date and status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order Date: $formattedDate',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              
                              Divider(height: 24),
                              
                              // Product name and quantity
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order['productName'] ?? 'Unknown product',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  
                                  Text(
                                    'Qty: ${order['quantity']} ${order['unit']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 8),
                              
                              // Farmer name
                              Text(
                                'Seller: ${order['farmerName'] ?? 'Unknown Farmer'}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Price and cancel option
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total: $formattedTotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  
                                  if (status == 'pending')
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Cancel Order'),
                                            content: Text('Are you sure you want to cancel this order?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _cancelOrder(order['id']);
                                                },
                                                style: TextButton.styleFrom(
                                                  // primary: Colors.red,
                                                ),
                                                child: Text('Yes, Cancel'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        // primary: Colors.red,
                                      ),
                                      child: Text('Cancel Order'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        statusText = 'Pending';
        break;
      case 'processing':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        statusText = 'Processing';
        break;
      case 'delivered':
      case 'completed':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        statusText = 'Completed';
        break;
      case 'cancelled':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        statusText = status.capitalize();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
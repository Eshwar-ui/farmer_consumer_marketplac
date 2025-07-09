import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';

class TransactionHistory extends StatefulWidget {
  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  
  // Mock transaction data
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactions();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadTransactions() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Mock active orders
      _activeOrders = [
        {
          'id': 'ORD123456',
          'date': DateTime.now().subtract(Duration(hours: 5)),
          'status': 'Confirmed',
          'farmer': 'Rajesh Kumar',
          'total': 750.0,
          'items': [
            {
              'name': 'Organic Tomatoes',
              'quantity': '5 kg',
              'price': 200.0,
            },
            {
              'name': 'Fresh Potatoes',
              'quantity': '10 kg',
              'price': 250.0,
            },
            {
              'name': 'Basmati Rice',
              'quantity': '5 kg',
              'price': 300.0,
            },
          ],
          'delivery': 'Apr 7, 2025',
          'paymentMethod': 'Cash on Delivery',
        },
        {
          'id': 'ORD123457',
          'date': DateTime.now().subtract(Duration(hours: 12)),
          'status': 'Processing',
          'farmer': 'Suresh Patel',
          'total': 600.0,
          'items': [
            {
              'name': 'Fresh Apples',
              'quantity': '3 kg',
              'price': 360.0,
            },
            {
              'name': 'Fresh Oranges',
              'quantity': '3 kg',
              'price': 240.0,
            },
          ],
          'delivery': 'Apr 7, 2025',
          'paymentMethod': 'Online Payment',
        },
      ];
      
      // Mock completed orders
      _completedOrders = [
        {
          'id': 'ORD123450',
          'date': DateTime.now().subtract(Duration(days: 5)),
          'status': 'Delivered',
          'farmer': 'Amit Singh',
          'total': 480.0,
          'items': [
            {
              'name': 'Organic Wheat Flour',
              'quantity': '8 kg',
              'price': 480.0,
            },
          ],
          'delivery': 'Apr 1, 2025',
          'paymentMethod': 'Online Payment',
        },
        {
          'id': 'ORD123445',
          'date': DateTime.now().subtract(Duration(days: 10)),
          'status': 'Delivered',
          'farmer': 'Rajesh Kumar',
          'total': 925.0,
          'items': [
            {
              'name': 'Organic Tomatoes',
              'quantity': '5 kg',
              'price': 200.0,
            },
            {
              'name': 'Fresh Potatoes',
              'quantity': '5 kg',
              'price': 125.0,
            },
            {
              'name': 'Fresh Onions',
              'quantity': '5 kg',
              'price': 175.0,
            },
            {
              'name': 'Organic Milk',
              'quantity': '5 L',
              'price': 425.0,
            },
          ],
          'delivery': 'Mar 27, 2025',
          'paymentMethod': 'Cash on Delivery',
        },
        {
          'id': 'ORD123430',
          'date': DateTime.now().subtract(Duration(days: 15)),
          'status': 'Delivered',
          'farmer': 'Suresh Patel',
          'total': 620.0,
          'items': [
            {
              'name': 'Fresh Apples',
              'quantity': '3 kg',
              'price': 360.0,
            },
            {
              'name': 'Fresh Oranges',
              'quantity': '3 kg',
              'price': 260.0,
            },
          ],
          'delivery': 'Mar 22, 2025',
          'paymentMethod': 'Online Payment',
        },
      ];
      
      // Mock cancelled orders
      _cancelledOrders = [
        {
          'id': 'ORD123452',
          'date': DateTime.now().subtract(Duration(days: 8)),
          'status': 'Cancelled',
          'farmer': 'Amit Singh',
          'total': 350.0,
          'items': [
            {
              'name': 'Fresh Onions',
              'quantity': '10 kg',
              'price': 350.0,
            },
          ],
          'cancellationReason': 'Out of stock',
          'paymentMethod': 'Cash on Delivery',
        },
      ];
      
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Orders',
        // showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab bar
                Container(
                  color: Colors.grey[100],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(text: 'Active (${_activeOrders.length})'),
                      Tab(text: 'Completed (${_completedOrders.length})'),
                      Tab(text: 'Cancelled (${_cancelledOrders.length})'),
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active orders
                      _buildOrdersList(_activeOrders),
                      
                      // Completed orders
                      _buildOrdersList(_completedOrders),
                      
                      // Cancelled orders
                      _buildOrdersList(_cancelledOrders),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64.0,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.0),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }
  
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusColor = _getStatusColor(order['status']);
    
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Text(
                    order['id'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.0),
              
              // Order info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14.0,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    _formatDate(order['date']),
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Icon(
                    Icons.person,
                    size: 14.0,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      order['farmer'],
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              
              // Order items preview
              Text(
                'Items:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.0),
              ...order['items'].take(2).map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 13.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['quantity'],
                          style: TextStyle(
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '₹${item['price']}',
                          style: TextStyle(
                            fontSize: 13.0,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (order['items'].length > 2)
                Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+${order['items'].length - 2} more items',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              SizedBox(height: 16.0),
              
              // Order total and actions
              Row(
                children: [
                  Text(
                    'Total: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${order['total'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Spacer(),
                  if (order['status'] == 'Confirmed' || order['status'] == 'Processing')
                    OutlinedButton(
                      onPressed: () {
                        // Show cancel confirmation
                        _showCancelConfirmation(order);
                      },
                      child: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                      ),
                    ),
                  if (order['status'] == 'Delivered')
                    OutlinedButton(
                      onPressed: () {
                        // Navigate to review screen
                      },
                      child: Text('Review'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.blue;
      case 'Processing':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      } else {
        return '${difference.inHours} hr ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              
              // Order ID and status
              Row(
                children: [
                  Text(
                    'Order ID: ${order['id']}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      order['status'],
                      style: TextStyle(
                        color: _getStatusColor(order['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              
              // Order date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14.0,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'Order Date: ${_formatDate(order['date'])}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              if (order['status'] == 'Cancelled' && order['cancellationReason'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14.0,
                        color: Colors.red,
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'Reason: ${order['cancellationReason']}',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              
              Divider(height: 32.0),
              
              // Farmer details
              Text(
                'Farmer Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['farmer'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Row(
                        children: [
                          Icon(
                            Icons.call,
                            size: 14.0,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            'Contact Farmer',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              Divider(height: 32.0),
              
              // Items list
              Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: order['items'].length,
                  itemBuilder: (context, index) {
                    final item = order['items'][index];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              Icons.shopping_basket,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Quantity: ${item['quantity']}',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item['price'].toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              Divider(height: 24.0),
              
              // Order summary
              Text(
                'Order Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Item Total'),
                  Text('₹${order['total'].toStringAsFixed(2)}'),
                ],
              ),
              SizedBox(height: 4.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee'),
                  Text('₹0.00'),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${order['total'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 14.0,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'Payment Method: ${order['paymentMethod']}',
                    style: TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
              if (order['delivery'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 14.0,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'Delivery: ${order['delivery']}',
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(height: 24.0),
              
              // Actions
              Row(
                children: [
                  if (order['status'] == 'Confirmed' || order['status'] == 'Processing')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCancelConfirmation(order);
                        },
                        child: Text('Cancel Order'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  if (order['status'] == 'Delivered')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to reorder
                          Navigator.pop(context);
                        },
                        child: Text('Reorder'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showCancelConfirmation(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cancel Order'),
          content: Text('Are you sure you want to cancel this order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Cancel order logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Refresh data
                _loadTransactions();
              },
              child: Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
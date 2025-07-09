import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';
import 'package:farmer_consumer_marketplace/widgets/loading_button.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  Map<String, dynamic> _orderDetails = {};
  List<Map<String, dynamic>> _statusHistory = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get order document
      final orderDoc =
          await _firebaseService.firestore
              .collection('orders')
              .doc(widget.orderId)
              .get();

      if (!orderDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order not found'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;

      // Get buyer details
      if (orderData['buyerId'] != null) {
        final buyerDoc =
            await _firebaseService.firestore
                .collection('users')
                .doc(orderData['buyerId'])
                .get();

        if (buyerDoc.exists) {
          Map<String, dynamic> buyerData =
              buyerDoc.data() as Map<String, dynamic>;
          orderData['buyerName'] = buyerData['name'] ?? 'Customer';
          orderData['buyerPhone'] = buyerData['phoneNumber'] ?? 'N/A';
          orderData['buyerEmail'] = buyerData['email'] ?? 'N/A';
        }
      }

      // Format dates
      if (orderData['createdAt'] != null) {
        DateTime createdAt = orderData['createdAt'].toDate();
        orderData['formattedCreatedAt'] = DateFormat(
          'MMM d, yyyy h:mm a',
        ).format(createdAt);
      } else {
        orderData['formattedCreatedAt'] = 'Unknown';
      }

      // Process status history
      List<Map<String, dynamic>> statusHistory = [];
      if (orderData['statusHistory'] != null) {
        for (var statusUpdate in orderData['statusHistory']) {
          Map<String, dynamic> historyItem = Map<String, dynamic>.from(
            statusUpdate,
          );

          // Format timestamp
          if (historyItem['timestamp'] != null) {
            DateTime timestamp = historyItem['timestamp'].toDate();
            historyItem['formattedTime'] = DateFormat(
              'MMM d, yyyy h:mm a',
            ).format(timestamp);
          } else {
            historyItem['formattedTime'] = 'Unknown';
          }

          // Get updater name if available
          if (historyItem['updatedBy'] != null) {
            final updaterDoc =
                await _firebaseService.firestore
                    .collection('users')
                    .doc(historyItem['updatedBy'])
                    .get();

            if (updaterDoc.exists) {
              Map<String, dynamic> updaterData =
                  updaterDoc.data() as Map<String, dynamic>;
              historyItem['updatedByName'] = updaterData['name'] ?? 'User';
            } else {
              historyItem['updatedByName'] = 'User';
            }
          }

          statusHistory.add(historyItem);
        }

        // Sort history by timestamp (newest first)
        statusHistory.sort((a, b) {
          if (a['timestamp'] == null) return 1;
          if (b['timestamp'] == null) return -1;
          return b['timestamp'].compareTo(a['timestamp']);
        });
      }

      setState(() {
        _orderDetails = orderData;
        _statusHistory = statusHistory;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading order details: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading order details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final success = await _firebaseService.updateOrderStatus(
        widget.orderId,
        newStatus,
      );

      if (success) {
        // Refresh order details
        await _loadOrderDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<void> _callBuyer() async {
    final phone = _orderDetails['buyerPhone'];
    if (phone == null || phone == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot make phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and Status
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ID',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        widget.orderId,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      _orderDetails['status'] ?? 'unknown',
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        _orderDetails['status'] ?? 'unknown',
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _orderDetails['status']?.toUpperCase() ??
                                        'UNKNOWN',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        _orderDetails['status'] ?? 'unknown',
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order Date',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  _orderDetails['formattedCreatedAt'] ??
                                      'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Payment Method',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  _orderDetails['paymentMethod'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Buyer Information
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Customer Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.phone,
                                    color: AppColors.primaryColor,
                                  ),
                                  onPressed: _callBuyer,
                                  tooltip: 'Call Customer',
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _orderDetails['buyerName'] ??
                                      'Unknown Customer',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(_orderDetails['buyerPhone'] ?? 'N/A'),
                              ],
                            ),
                            if (_orderDetails['buyerEmail'] != null &&
                                _orderDetails['buyerEmail'] != 'N/A')
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(_orderDetails['buyerEmail']),
                                  ],
                                ),
                              ),
                            SizedBox(height: 16),
                            Text(
                              'Delivery Address',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _orderDetails['deliveryAddress'] ??
                                          'No address provided',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Order Items
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Product details
                            ListTile(
                              contentPadding: EdgeInsets.all(0),
                              title: Text(
                                _orderDetails['productName'] ??
                                    'Unknown Product',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Quantity: ${_orderDetails['quantity']} ${_orderDetails['unit'] ?? 'units'}',
                              ),
                              trailing: Text(
                                '₹${currencyFormat.format(_orderDetails['unitPrice'] ?? 0)}/${_orderDetails['unit'] ?? 'unit'}',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

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
                                  '₹${currencyFormat.format(_orderDetails['totalAmount'] ?? 0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Status History
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            _statusHistory.isEmpty
                                ? Center(
                                  child: Text('No status history available'),
                                )
                                : _buildStatusTimeline(),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Action Buttons - Only show if order is not completed or cancelled
                    if (_orderDetails['status'] != 'completed' &&
                        _orderDetails['status'] != 'cancelled')
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),

                              // Actions based on current status
                              if (_orderDetails['status'] == 'pending')
                                Column(
                                  children: [
                                    LoadingButton(
                                      isLoading: _isUpdatingStatus,
                                      onPressed:
                                          () =>
                                              _updateOrderStatus('processing'),
                                      text: 'Accept Order',
                                      loadingText: 'Updating...',
                                      // backgroundColor: Colors.green,
                                    ),
                                    SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed:
                                          _isUpdatingStatus
                                              ? null
                                              : () => _updateOrderStatus(
                                                'cancelled',
                                              ),
                                      child: Text('Reject Order'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        minimumSize: Size(double.infinity, 50),
                                        side: BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                )
                              else if (_orderDetails['status'] == 'processing')
                                LoadingButton(
                                  isLoading: _isUpdatingStatus,
                                  onPressed:
                                      () => _updateOrderStatus('shipped'),
                                  text: 'Mark as Delivered',
                                  loadingText: 'Updating...',
                                  // backgroundColor: Colors.purple,
                                )
                              else if (_orderDetails['status'] == 'delivered')
                                LoadingButton(
                                  isLoading: _isUpdatingStatus,
                                  onPressed:
                                      () => _updateOrderStatus('completed'),
                                  text: 'Mark as Completed',
                                  loadingText: 'Updating...',
                                  // backgroundColor: Colors.green.shade700,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      children: List.generate(_statusHistory.length, (index) {
        final statusUpdate = _statusHistory[index];
        final bool isLast = index == _statusHistory.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline connector and dot
            Container(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusUpdate['status']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 50,
                      color: Colors.grey[300],
                      margin: EdgeInsets.only(left: 5),
                    ),
                ],
              ),
            ),

            SizedBox(width: 8),

            // Status update details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        statusUpdate['status'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusUpdate['status']?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(statusUpdate['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    statusUpdate['formattedTime'] ?? 'Unknown time',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),

                  SizedBox(height: 4),

                  if (statusUpdate['updatedByName'] != null)
                    Text(
                      'Updated by: ${statusUpdate['updatedByName']}',
                      style: TextStyle(fontSize: 13),
                    ),

                  if (statusUpdate['reason'] != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Reason: ${statusUpdate['reason']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  SizedBox(height: isLast ? 0 : 16),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

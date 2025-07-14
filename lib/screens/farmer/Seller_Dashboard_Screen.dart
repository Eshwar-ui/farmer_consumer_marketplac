import 'package:farmer_consumer_marketplace/utils/LogoutButton.dart';
import 'package:farmer_consumer_marketplace/widgets/Order_Details_Screen.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';
import 'package:badges/badges.dart' as badges;

class SellerDashboardScreen extends StatefulWidget {
  final String userId;

  const SellerDashboardScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentOrders = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Load recent orders
      final orders = await _firebaseService.getSellerOrders(widget.userId);

      // Get only the 5 most recent orders
      final recentOrders = orders.take(5).toList();

      // Count unread notifications
      final notifications = await _firebaseService.getUserNotifications(
        widget.userId,
      );
      final unreadCount =
          notifications
              .where((notification) => notification['isRead'] != true)
              .length;

      if (!mounted) return;
      setState(() {
        _recentOrders = recentOrders;
        _unreadNotifications = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildOrderStatusCard(String status, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Orders'),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Orders status cards
                      Row(
                        children: [
                          _buildOrderStatusCard(
                            'New Orders',
                            _recentOrders
                                .where((order) => order['status'] == 'pending')
                                .length,
                            Colors.orange,
                          ),
                          SizedBox(width: 8),
                          _buildOrderStatusCard(
                            'Processing',
                            _recentOrders
                                .where(
                                  (order) => order['status'] == 'processing',
                                )
                                .length,
                            Colors.blue,
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Row(
                        children: [
                          _buildOrderStatusCard(
                            'Shipped',
                            _recentOrders
                                .where((order) => order['status'] == 'shipped')
                                .length,
                            Colors.purple,
                          ),
                          SizedBox(width: 8),
                          _buildOrderStatusCard(
                            'Delivered',
                            _recentOrders
                                .where(
                                  (order) => order['status'] == 'delivered',
                                )
                                .length,
                            Colors.green,
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Recent orders
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Orders',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to all orders screen
                                      // This would be implemented separately
                                    },
                                    child: Text('View All'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),

                              _recentOrders.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No orders yet',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: _recentOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = _recentOrders[index];
                                      final DateTime createdAt =
                                          order['createdAt']?.toDate() ??
                                          DateTime.now();
                                      final String formattedDate = DateFormat(
                                        'MMM d, h:mm a',
                                      ).format(createdAt);

                                      return InkWell(
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      OrderDetailsScreen(
                                                        orderId: order['id'],
                                                      ),
                                            ),
                                          );

                                          // Refresh data when returning from order details
                                          _loadDashboardData();
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Status indicator
                                              Container(
                                                width: 12,
                                                height: 12,
                                                margin: EdgeInsets.only(
                                                  top: 4,
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _getStatusColor(
                                                    order['status'] ??
                                                        'unknown',
                                                  ),
                                                ),
                                              ),

                                              // Order details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          order['productName'] ??
                                                              'Unknown Product',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          '₹${NumberFormat('#,##0.00').format(order['totalAmount'] ?? 0)}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                AppColors
                                                                    .primaryColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Qty: ${order['quantity']} ${order['unit'] ?? 'units'}',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: _getStatusColor(
                                                              order['status'] ??
                                                                  'unknown',
                                                            ).withOpacity(0.1),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            order['status']
                                                                    ?.toUpperCase() ??
                                                                'UNKNOWN',
                                                            style: TextStyle(
                                                              color: _getStatusColor(
                                                                order['status'] ??
                                                                    'unknown',
                                                              ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .person_outline,
                                                              size: 14,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              order['buyerName'] ??
                                                                  'Unknown Customer',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          formattedDate,
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Quick Actions
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),

                              GridView.count(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5,
                                children: [
                                  _buildActionCard(
                                    icon: Icons.add_box,
                                    title: 'Add Product',
                                    color: Colors.green,
                                    onTap: () {
                                      // Navigate to add product screen
                                    },
                                  ),
                                  _buildActionCard(
                                    icon: Icons.inventory,
                                    title: 'Manage Inventory',
                                    color: Colors.blue,
                                    onTap: () {
                                      // Navigate to inventory screen
                                    },
                                  ),
                                  _buildActionCard(
                                    icon: Icons.analytics,
                                    title: 'Sales Reports',
                                    color: Colors.purple,
                                    onTap: () {
                                      // Navigate to sales reports screen
                                    },
                                  ),
                                  _buildActionCard(
                                    icon: Icons.shopping_bag,
                                    title: 'View Orders',
                                    color: Colors.orange,
                                    onTap: () {
                                      // Navigate to all orders screen
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // color: color.  shade700,
              ),
            ),
          ],
        ),
      ),
    );
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
}

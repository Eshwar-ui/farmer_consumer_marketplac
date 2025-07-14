import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/services/auth_service.dart';
import 'dart:convert'; // Added for base64Decode

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load user profile from Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userProfile = userDoc.data();
          });
        }

        // Load recent orders
        final ordersSnapshot =
            await _firestore
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('orderDate', descending: true)
                .limit(5)
                .get();

        setState(() {
          _recentOrders =
              ordersSnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile data')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logOut() async {
    try {
      await _auth.signOut();
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to log out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
              Navigator.of(context).pushNamed('/edit-profile');
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _userProfile == null
              ? _buildNoProfileView()
              : _buildProfileView(),
    );
  }

  Widget _buildNoProfileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 100, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Profile not found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Your profile information is not available'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to create profile screen
              Navigator.of(context).pushNamed('/edit-profile');
            },
            child: Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                _buildProfileAvatar(),
                SizedBox(height: 16),
                Text(
                  _userProfile!['name'] ?? user?.displayName ?? 'User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Contact info section
          _buildSectionHeader('Contact Information'),
          _buildInfoCard([
            _buildInfoRow(
              Icons.phone,
              'Phone',
              _userProfile!['phone'] ?? 'Not provided',
            ),
            _buildInfoRow(
              Icons.location_on,
              'Address',
              _userProfile!['address'] ?? 'Not provided',
            ),
          ]),

          SizedBox(height: 24),

          // Preferences section
          _buildSectionHeader('Preferences'),
          _buildInfoCard([
            _buildInfoRow(
              Icons.eco,
              'Preferred Categories',
              (_userProfile!['preferredCategories'] as List<dynamic>?)?.join(
                    ', ',
                  ) ??
                  'Not specified',
            ),
            _buildPreferenceToggle(
              'Notification Preferences',
              _userProfile!['notificationsEnabled'] ?? true,
            ),
          ]),

          SizedBox(height: 24),

          // Recent orders section
          _buildSectionHeader('Recent Orders'),
          _recentOrders.isEmpty
              ? _buildEmptyOrdersCard()
              : Column(
                children:
                    _recentOrders
                        .map((order) => _buildOrderCard(order))
                        .toList(),
              ),

          SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Log Out'),
              onPressed: _logOut,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final profileImageBytes = _userProfile?['profileImageBytes'];
    final profileImageUrl =
        _userProfile?['photoUrl'] ?? _userProfile?['profileImageUrl'];
    Widget avatarWidget;
    if (profileImageBytes != null && (profileImageBytes as String).isNotEmpty) {
      try {
        final bytes = base64Decode(profileImageBytes);
        avatarWidget = ClipOval(
          child: Image.memory(
            bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _networkOrDefaultAvatar(profileImageUrl);
            },
          ),
        );
      } catch (_) {
        avatarWidget = _networkOrDefaultAvatar(profileImageUrl);
      }
    } else {
      avatarWidget = _networkOrDefaultAvatar(profileImageUrl);
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.10),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: avatarWidget,
    );
  }

  Widget _networkOrDefaultAvatar(String? url) {
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/app_logo.png',
          image: url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stackTrace) {
            return Icon(Icons.agriculture, size: 50, color: Colors.green[700]);
          },
        ),
      );
    }
    return Icon(Icons.agriculture, size: 50, color: Colors.green[700]);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceToggle(String label, bool value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(label, style: TextStyle(fontSize: 16)),
            ],
          ),
          Switch(
            value: value,
            onChanged: (newValue) async {
              try {
                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .update({'notificationsEnabled': newValue});

                setState(() {
                  _userProfile!['notificationsEnabled'] = newValue;
                });
              } catch (e) {
                print('Error updating notification preference: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_bag, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No recent orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your order history will appear here',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Navigate to marketplace
                  Navigator.of(context).pushNamed('/marketplace');
                },
                child: Text('Browse Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderDate =
        order['orderDate'] != null
            ? DateTime.parse(order['orderDate'])
            : DateTime.now();

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to order details
          Navigator.of(
            context,
          ).pushNamed('/order-details', arguments: order['id']);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['id'].toString().substring(0, 6)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['status'] ?? 'Processing',
                      style: TextStyle(
                        color: _getStatusColor(order['status']),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${order['items']?.length ?? 0} items • ${_formatDate(orderDate)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₹${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Confirmed':
        return Colors.blue;
      case 'Processing':
        return Colors.orange;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

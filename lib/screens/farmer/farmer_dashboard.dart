import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/MarketPriceWidget.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/Total_Revenue_Widget.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/Seller_Dashboard_Screen.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/crop_recommendation.dart';
import 'package:farmer_consumer_marketplace/widgets/common/weather_Screen.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/inventory_management.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/price_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/market_trend_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/farmer_profile_screen.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/widgets/common/bottom_nav.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/sales_page.dart';
import 'dart:convert';

class FarmerDashboard extends StatefulWidget {
  final UserModel user;

  const FarmerDashboard({Key? key, required this.user}) : super(key: key);
  @override
  _FarmerDashboardState createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardContent(
        user: widget.user,
        onProfileTap: () {
          setState(() {
            _currentIndex = 4; // Profile tab index
          });
        },
        onTabChange: (int idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
      ),
      InventoryManagement(),
      SellerDashboardScreen(userId: widget.user.id),
      SalesPage(),
      FarmerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFf8fff8), Color(0xFFe0ffe0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_currentIndex],
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
            BottomNavItem(icon: Icons.inventory, label: 'Inventory'),
            BottomNavItem(icon: Icons.shopping_bag, label: 'Orders'),
            BottomNavItem(icon: Icons.bar_chart, label: 'Sales'),
            BottomNavItem(icon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  final UserModel user;
  final void Function()? onProfileTap;
  final void Function(int)? onTabChange;
  const DashboardContent({
    Key? key,
    required this.user,
    this.onProfileTap,
    this.onTabChange,
  }) : super(key: key);
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final FirebaseService _firebaseService = FirebaseService();
  final Map<String, dynamic> _weatherInfo = {
    'temperature': '32°C',
    'condition': 'Sunny',
    'rainfall': '0mm',
    'humidity': '65%',
  };
  List<Map<String, dynamic>> _inventorySummary = [];
  bool _isLoadingInventory = true;
  String? _inventoryError;
  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoadingSales = true;
  String? _salesError;

  @override
  void initState() {
    super.initState();
    _loadInventorySummary();
    _loadRecentSales();
  }

  Future<void> _loadInventorySummary() async {
    if (!mounted) return;
    setState(() {
      _isLoadingInventory = true;
      _inventoryError = null;
    });

    try {
      // Get inventory from Firebase
      List<Map<String, dynamic>> inventory =
          await _firebaseService.getFarmerInventory();

      if (!mounted) return;
      if (inventory.isEmpty) {
        setState(() {
          _inventorySummary = [];
          _isLoadingInventory = false;
        });
        return;
      }

      // Calculate summary by category
      Map<String, Map<String, dynamic>> categoryMap = {};

      for (var item in inventory) {
        String category = item['category'] ?? 'Uncategorized';

        if (!categoryMap.containsKey(category)) {
          categoryMap[category] = {
            'category': category,
            'quantity': 0.0, // Changed to double
            'value': 0.0, // Changed to double
          };
        }

        // Safely convert values to double
        double itemQuantity = 0.0;
        double itemValue = 0.0;

        if (item['quantity'] != null) {
          itemQuantity = double.parse(item['quantity'].toString());
        }

        if (item['totalValue'] != null) {
          itemValue = double.parse(item['totalValue'].toString());
        } else if (item['unitPrice'] != null && item['quantity'] != null) {
          // Calculate total value if not provided directly
          double unitPrice = double.parse(item['unitPrice'].toString());
          double quantity = double.parse(item['quantity'].toString());
          itemValue = unitPrice * quantity;
        }

        // Update category totals (safely with double values)
        categoryMap[category]!['quantity'] =
            (categoryMap[category]!['quantity'] as double) + itemQuantity;
        categoryMap[category]!['value'] =
            (categoryMap[category]!['value'] as double) + itemValue;
      }

      if (!mounted) return;
      setState(() {
        _inventorySummary = categoryMap.values.toList();
        _isLoadingInventory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inventoryError = 'Error loading inventory: $e';
        _isLoadingInventory = false;
      });
    }
  }

  Future<void> _loadRecentSales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSales = true;
      _salesError = null;
    });

    try {
      // Get recent sales from Firebase using the proper method
      List<Map<String, dynamic>> sales = await _firebaseService.getRecentSales(
        limit: 3,
      );

      if (!mounted) return;
      setState(() {
        _recentSales = sales;
        _isLoadingSales = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salesError = 'Error loading sales: $e';
        _isLoadingSales = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomAppBar(
          centerTitle: false,
          title: 'Farmer Dashboard',
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                // TODO: Implement notifications navigation
              },
            ),
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                if (widget.onProfileTap != null) widget.onProfileTap!();
              },
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 18.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 18.0),
                TotalRevenueWidget(),
                const SizedBox(height: 18.0),
                _buildInventorySummary(context),
                const SizedBox(height: 18.0),
                _buildRecentSales(),
                const SizedBox(height: 18.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final user = widget.user;
    Widget avatarWidget;
    bool imageLoaded = false;
    // Try profileImageBytes (base64)
    if (user.profileImageBytes != null && user.profileImageBytes!.isNotEmpty) {
      try {
        final bytes = base64Decode(user.profileImageBytes!);
        avatarWidget = ClipOval(
          child: Image.memory(
            bytes,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to next option
              return _networkOrDefaultAvatar(user);
            },
          ),
        );
        imageLoaded = true;
      } catch (_) {
        avatarWidget = _networkOrDefaultAvatar(user);
      }
    } else {
      avatarWidget = _networkOrDefaultAvatar(user);
    }
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Card(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.0),
        ),
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            gradient: LinearGradient(
              colors: [Color(0xFFe0ffe0), Color(0xFFf8fff8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage('assets/app_logo.png'),
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              opacity: 0.10,
            ),
            border: Border.all(
              color: Colors.green,
              width: 2.5,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.13),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
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
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.green[100],
                        child: avatarWidget,
                      ),
                    ),
                    if (user.role == 'farmer')
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'No Name',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.green[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isNotEmpty ? user.email : 'No Email',
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.green[400],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (user.phoneNumber != null &&
                          user.phoneNumber!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.green[400],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.phoneNumber!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _networkOrDefaultAvatar(UserModel user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/app_logo.png',
          image: user.profileImageUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stackTrace) {
            return Icon(Icons.agriculture, size: 40, color: Colors.green[700]);
          },
        ),
      );
    }
    return Icon(Icons.agriculture, size: 40, color: Colors.green[700]);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              'Add Product',
              Icons.add_circle,
              Colors.green,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => InventoryManagement()),
                );
              },
            ),
            _buildActionButton(
              'Check Prices',
              Icons.attach_money,
              Colors.amber,
              () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => PriceAnalysis()));
              },
            ),
            _buildActionButton('Weather', Icons.wb_sunny, Colors.blue, () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => WeatherScreen()));
            }),
            _buildActionButton('Profile', Icons.person, Colors.purple, () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => FarmerProfileScreen()));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 18.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.0),
            const SizedBox(height: 8.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Text(
                      'Inventory Summary',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (widget.onTabChange != null) {
                      widget.onTabChange!(1); // 1 = Inventory tab
                    }
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            _isLoadingInventory
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _inventoryError != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _inventoryError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                )
                : _inventorySummary.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/farm_empty.png',
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.inventory_2,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No inventory items found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => InventoryManagement(),
                              ),
                            );
                          },
                          child: Text('Add Products'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(16),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.green[50],
                  ),
                  child: Table(
                    columnWidths: {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.green[100]!,
                              width: 1.0,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Value (₹)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ..._inventorySummary.asMap().entries.map((entry) {
                        final item = entry.value;
                        final isEven = entry.key % 2 == 0;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.green[50] : Colors.white,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(item['category']),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(item['quantity'].toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text('₹${item['value']}'),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Text(
                      'Recent Sales',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (widget.onTabChange != null) {
                      widget.onTabChange!(3); // 3 = Sales tab
                    }
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            _isLoadingSales
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _salesError != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _salesError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                )
                : _recentSales.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/farm_empty.png',
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.shopping_cart,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No sales recorded yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
                : Column(
                  children:
                      _recentSales.map((sale) {
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Icon(
                                Icons.shopping_cart,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              sale['product'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${sale['quantity']} • ${sale['date']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            trailing: Text(
                              sale['price'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
          ],
        ),
      ),
    );
  }
}

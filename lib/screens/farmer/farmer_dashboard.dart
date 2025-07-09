import 'package:farmer_consumer_marketplace/models/user_model.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/MarketPriceWidget.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/Total_Revenue_Widget.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/Seller_Dashboard_Screen.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/crop_recommendation.dart';
import 'package:farmer_consumer_marketplace/widgets/common/weather_Screen.dart';
import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/inventory_management.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/price_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/market_trend_analysis.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/farmer_profile_screen.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/widgets/common/bottom_nav.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:intl/intl.dart';

class FarmerDashboard extends StatefulWidget {
  final UserModel user;

  const FarmerDashboard({
    Key? key,
    required this.user,
  }) : super(key: key);
  @override
  _FarmerDashboardState createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;

  // Initialize the screens in build method to access widget.user
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens here to have access to widget.user
    _screens = [
      DashboardContent(),
      InventoryManagement(),
      CropRecommendationScreen(),
      MarketPriceScreen(),
      // WeatherScreen(),
      SellerDashboardScreen(userId: widget.user.id)  // Pass the userId here
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Farmer Dashboard',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications screen
              // Navigator.of(context).push(
              //   MaterialPageRoute(
              //     builder: (_) => NotificationsScreen(userId: widget.user.id),
              //   ),
              // );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FarmerProfileScreen()),
              );
            },
          ),
        ],
      ),
      
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
          BottomNavItem(icon: Icons.search, label: 'Find'),
          BottomNavItem(icon: Icons.trending_up, label: 'Prices'),
          BottomNavItem(icon: Icons.shopping_bag, label: 'Orders'),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Weather information - to be replaced with real data
  final Map<String, dynamic> _weatherInfo = {
    'temperature': '32°C',
    'condition': 'Sunny',
    'rainfall': '0mm',
    'humidity': '65%',
  };

  // Inventory summary
  List<Map<String, dynamic>> _inventorySummary = [];
  bool _isLoadingInventory = true;
  String? _inventoryError;

  // Recent sales
  List<Map<String, dynamic>> _recentSales = [];
  bool _isLoadingSales = true;
  String? _salesError;

  @override
  void initState() {
    super.initState();
    _loadInventorySummary();
    _loadRecentSales();
  }

  // Update the loadInventorySummary method in _DashboardContentState class
Future<void> _loadInventorySummary() async {
  setState(() {
    _isLoadingInventory = true;
    _inventoryError = null;
  });

  try {
    // Get inventory from Firebase
    List<Map<String, dynamic>> inventory = await _firebaseService.getFarmerInventory();
    
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
          'quantity': 0.0,  // Changed to double
          'value': 0.0,     // Changed to double
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
      categoryMap[category]!['quantity'] = (categoryMap[category]!['quantity'] as double) + itemQuantity;
      categoryMap[category]!['value'] = (categoryMap[category]!['value'] as double) + itemValue;
    }
    
    setState(() {
      _inventorySummary = categoryMap.values.toList();
      _isLoadingInventory = false;
    });
  } catch (e) {
    setState(() {
      _inventoryError = 'Error loading inventory: $e';
      _isLoadingInventory = false;
    });
  }
}

  Future<void> _loadRecentSales() async {
    setState(() {
      _isLoadingSales = true;
      _salesError = null;
    });

    try {
      // Get recent sales from Firebase using the proper method
      List<Map<String, dynamic>> sales = await _firebaseService.getRecentSales(limit: 3);
      
      setState(() {
        _recentSales = sales;
        _isLoadingSales = false;
      });
    } catch (e) {
      setState(() {
        _salesError = 'Error loading sales: $e';
        _isLoadingSales = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadInventorySummary(),
          _loadRecentSales(),
        ]);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather widget - compact version for dashboard
            _buildWeatherCard(),
  
            const SizedBox(height: 16.0),
  
            // Quick actions
            _buildQuickActions(context),
  
            const SizedBox(height: 16.0),
  
            // Revenue chart - now using real data from Firebase
            TotalRevenueWidget(),
  
            const SizedBox(height: 16.0),
  
            // Inventory summary - now using real data from Firebase
            _buildInventorySummary(context),
  
            const SizedBox(height: 16.0),
  
            // Recent sales - now using real data from Firebase
            _buildRecentSales(),
  
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          // Navigate to detailed weather screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WeatherScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.wb_sunny, size: 48.0, color: Colors.amber),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Weather',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _weatherInfoItem(
                          'Temperature',
                          _weatherInfo['temperature'],
                          Icons.thermostat,
                        ),
                        _weatherInfoItem(
                          'Rainfall',
                          _weatherInfo['rainfall'],
                          Icons.water_drop,
                        ),
                        _weatherInfoItem(
                          'Humidity',
                          _weatherInfo['humidity'],
                          Icons.opacity,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20.0),
        const SizedBox(height: 4.0),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12.0, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PriceAnalysis()),
                );
              },
            ),
            _buildActionButton(
              'Weather',
              Icons.wb_sunny,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WeatherScreen()),
                );
              },
            ),
            _buildActionButton(
              'Profile',
              Icons.person,
              Colors.purple,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FarmerProfileScreen()),
                );
              },
            ),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28.0),
          ),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySummary(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Inventory Summary',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => InventoryManagement()),
                    );
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
                                  Icon(
                                    Icons.inventory_2,
                                    size: 48,
                                    color: Colors.grey[400],
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
                                            builder: (_) => InventoryManagement()),
                                      );
                                    },
                                    child: Text('Add Products'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Table(
                            columnWidths: {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(2),
                              2: FlexColumnWidth(2),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Category',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Quantity',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Value (₹)',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              ..._inventorySummary.map((item) => TableRow(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(item['category']),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(item['quantity'].toString()),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text('₹${item['value']}'),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSales() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Sales',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to sales history when implemented
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sales history coming soon')),
                    );
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
                                  Icon(
                                    Icons.shopping_cart,
                                    size: 48,
                                    color: Colors.grey[400],
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
                            children: _recentSales.map((sale) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sale['product'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${sale['quantity']} • ${sale['date']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      sale['price'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
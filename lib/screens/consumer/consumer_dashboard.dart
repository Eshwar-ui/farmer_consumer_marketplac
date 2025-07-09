import 'package:farmer_consumer_marketplace/utils/LogoutButton.dart';
import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:farmer_consumer_marketplace/models/user_model.dart';
import 'package:farmer_consumer_marketplace/widgets/market_product_card.dart';
import 'package:farmer_consumer_marketplace/widgets/category_selector.dart';
import 'package:farmer_consumer_marketplace/widgets/product_detail_screen.dart';
import 'package:farmer_consumer_marketplace/widgets/search_screen.dart';
import 'package:farmer_consumer_marketplace/widgets/orders_screen.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';

class ConsumerDashboard extends StatefulWidget {
  final UserModel user;

  const ConsumerDashboard({Key? key, required this.user}) : super(key: key);

  @override
  _ConsumerDashboardState createState() => _ConsumerDashboardState();
}

class _ConsumerDashboardState extends State<ConsumerDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all available products from inventory
      List<Map<String, dynamic>> products = await _firebaseService.getAllAvailableProducts();
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products. Please try again.'))
      );
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      
      if (category == 'All') {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) => 
          product['category'] == category).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(products: _products),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_basket),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersScreen(userId: widget.user.id),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: LogoutButton(),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Location header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivering to: ${widget.user.location}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category selector
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CategorySelector(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _filterByCategory,
                  ),
                ),
                
                // Product grid
                Expanded(
                  child: _filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          _selectedCategory == 'All'
                            ? 'No products available'
                            : 'No products in this category',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return MarketProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    product: product,
                                    userId: widget.user.id,
                                  ),
                                ),
                              ).then((_) => _loadProducts());
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
      ),
    );
  }
}
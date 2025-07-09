import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/models/product_model.dart';
import 'package:farmer_consumer_marketplace/screens/consumer/search_filter.dart';

class MarketplaceView extends StatefulWidget {
  @override
  _MarketplaceViewState createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<MarketplaceView> {
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _selectedSort = 'Price: Low to High';
  bool _organicOnly = false;
  
  // Mock product list
  List<ProductModel> _products = [];
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  void _loadProducts() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Create mock products
      final List<ProductModel> mockProducts = [
        ProductModel(
          id: '1',
          farmerId: 'farmer1',
          name: 'Organic Tomatoes',
          description: 'Fresh organic tomatoes',
          category: ProductCategory.vegetables,
          price: 40.0,
          quantity: 100.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 2)),
          listedDate: DateTime.now(),
          organic: true,
          location: 'Nashik, Maharashtra',
        ),
        ProductModel(
          id: '2',
          farmerId: 'farmer2',
          name: 'Fresh Apples',
          description: 'Kashmiri apples',
          category: ProductCategory.fruits,
          price: 120.0,
          quantity: 75.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 3)),
          listedDate: DateTime.now(),
          organic: true,
          location: 'Shimla, Himachal Pradesh',
        ),
        ProductModel(
          id: '3',
          farmerId: 'farmer3',
          name: 'Basmati Rice',
          description: 'Premium basmati rice',
          category: ProductCategory.grains,
          price: 80.0,
          quantity: 200.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 15)),
          listedDate: DateTime.now(),
          organic: false,
          location: 'Dehradun, Uttarakhand',
        ),
        ProductModel(
          id: '4',
          farmerId: 'farmer1',
          name: 'Fresh Potatoes',
          description: 'Farm fresh potatoes',
          category: ProductCategory.vegetables,
          price: 25.0,
          quantity: 150.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 5)),
          listedDate: DateTime.now(),
          organic: false,
          location: 'Nashik, Maharashtra',
        ),
        ProductModel(
          id: '5',
          farmerId: 'farmer4',
          name: 'Organic Wheat Flour',
          description: 'Stone-ground organic wheat flour',
          category: ProductCategory.grains,
          price: 60.0,
          quantity: 100.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 20)),
          listedDate: DateTime.now(),
          organic: true,
          location: 'Indore, Madhya Pradesh',
        ),
        ProductModel(
          id: '6',
          farmerId: 'farmer2',
          name: 'Fresh Oranges',
          description: 'Juicy Nagpur oranges',
          category: ProductCategory.fruits,
          price: 90.0,
          quantity: 80.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 4)),
          listedDate: DateTime.now(),
          organic: false,
          location: 'Nagpur, Maharashtra',
        ),
        ProductModel(
          id: '7',
          farmerId: 'farmer5',
          name: 'Organic Milk',
          description: 'Fresh organic cow milk',
          category: ProductCategory.dairy,
          price: 50.0,
          quantity: 50.0,
          unit: ProductUnit.liter,
          harvestDate: DateTime.now(),
          listedDate: DateTime.now(),
          organic: true,
          location: 'Anand, Gujarat',
        ),
        ProductModel(
          id: '8',
          farmerId: 'farmer3',
          name: 'Fresh Onions',
          description: 'Farm fresh red onions',
          category: ProductCategory.vegetables,
          price: 35.0,
          quantity: 120.0,
          unit: ProductUnit.kg,
          harvestDate: DateTime.now().subtract(Duration(days: 6)),
          listedDate: DateTime.now(),
          organic: false,
          location: 'Nashik, Maharashtra',
        ),
      ];
      
      setState(() {
        _products = mockProducts;
        _isLoading = false;
      });
    });
  }
  
  List<ProductModel> _getFilteredProducts() {
    List<ProductModel> filteredProducts = List.from(_products);
    
    // Filter by category
    if (_selectedCategory != 'All') {
      final category = _getCategoryFromString(_selectedCategory);
      filteredProducts = filteredProducts.where((product) => 
        product.category == category
      ).toList();
    }
    
    // Filter organic only
    if (_organicOnly) {
      filteredProducts = filteredProducts.where((product) => 
        product.organic == true
      ).toList();
    }
    
    // Sort products
    switch (_selectedSort) {
      case 'Price: Low to High':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest First':
        filteredProducts.sort((a, b) => b.listedDate.compareTo(a.listedDate));
        break;
      case 'Oldest First':
        filteredProducts.sort((a, b) => a.listedDate.compareTo(b.listedDate));
        break;
    }
    
    return filteredProducts;
  }
  
  ProductCategory _getCategoryFromString(String category) {
    switch (category) {
      case 'Vegetables':
        return ProductCategory.vegetables;
      case 'Fruits':
        return ProductCategory.fruits;
      case 'Grains':
        return ProductCategory.grains;
      case 'Dairy':
        return ProductCategory.dairy;
      case 'Poultry':
        return ProductCategory.poultry;
      case 'Meat':
        return ProductCategory.meat;
      default:
        return ProductCategory.other;
    }
  }
  
  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort & Filter',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                  // Category filter
                  Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    height: 40.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        'All',
                        'Vegetables',
                        'Fruits',
                        'Grains',
                        'Dairy',
                        'Poultry',
                        'Meat',
                      ].map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setSheetState(() {
                                _selectedCategory = category;
                              });
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                  // Organic filter
                  Row(
                    children: [
                      Checkbox(
                        value: _organicOnly,
                        onChanged: (value) {
                          setSheetState(() {
                            _organicOnly = value!;
                          });
                          setState(() {
                            _organicOnly = value!;
                          });
                        },
                      ),
                      Text('Organic products only'),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  
                  // Sort options
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Column(
                    children: [
                      'Price: Low to High',
                      'Price: High to Low',
                      'Newest First',
                      'Oldest First',
                    ].map((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: _selectedSort,
                        onChanged: (value) {
                          setSheetState(() {
                            _selectedSort = value!;
                          });
                          setState(() {
                            _selectedSort = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Marketplace',
        // showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchFilter()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sort & Filter bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${filteredProducts.length} Products',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      TextButton.icon(
                        onPressed: _showSortFilterBottomSheet,
                        icon: Icon(Icons.filter_list),
                        label: Text('Sort & Filter'),
                      ),
                    ],
                  ),
                ),
                
                // Product grid
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64.0,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.0),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                    _organicOnly = false;
                                    _selectedSort = 'Price: Low to High';
                                  });
                                },
                                child: Text('Clear Filters'),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () {
        // Navigate to product details
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: 120.0,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getIconForCategory(product.category),
                      size: 48.0,
                      color: Colors.grey[400],
                    ),
                  ),
                  if (product.organic)
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          'Organic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}/${_getUnitString(product.unit)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12.0,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          product.location.split(',').first,
                          style: TextStyle(
                            fontSize: 10.0,
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
    );
  }
  
  IconData _getIconForCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.fruits:
        return Icons.apple;
      case ProductCategory.vegetables:
        return Icons.eco;
      case ProductCategory.grains:
        return Icons.grain;
      case ProductCategory.dairy:
        return Icons.water_drop;
      case ProductCategory.poultry:
        return Icons.egg;
      case ProductCategory.meat:
        return Icons.restaurant;
      default:
        return Icons.inventory_2;
    }
  }
  
  String _getUnitString(ProductUnit unit) {
    switch (unit) {
      case ProductUnit.kg:
        return 'kg';
      case ProductUnit.gram:
        return 'g';
      case ProductUnit.liter:
        return 'L';
      case ProductUnit.piece:
        return 'pc';
      case ProductUnit.dozen:
        return 'dz';
      case ProductUnit.quintal:
        return 'qtl';
      case ProductUnit.ton:
        return 'ton';
    }
  }
}
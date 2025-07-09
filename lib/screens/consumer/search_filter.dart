import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/models/product_model.dart';

class SearchFilter extends StatefulWidget {
  @override
  _SearchFilterState createState() => _SearchFilterState();
}

class _SearchFilterState extends State<SearchFilter> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  
  // Filter state
  RangeValues _priceRange = RangeValues(0, 500);
  List<String> _selectedCategories = [];
  bool _organicOnly = false;
  double _maxDistance = 50.0; // in km
  String _sortBy = 'Relevance';
  
  // Mock data
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _recentSearches = [
    {'query': 'Organic vegetables', 'timestamp': DateTime.now().subtract(Duration(hours: 2))},
    {'query': 'Fresh fruits', 'timestamp': DateTime.now().subtract(Duration(days: 1))},
    {'query': 'Rice', 'timestamp': DateTime.now().subtract(Duration(days: 2))},
  ];
  
  // Category options
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Vegetables', 'icon': Icons.eco},
    {'name': 'Fruits', 'icon': Icons.apple},
    {'name': 'Grains', 'icon': Icons.grain},
    {'name': 'Dairy', 'icon': Icons.water_drop},
    {'name': 'Poultry', 'icon': Icons.egg},
    {'name': 'Meat', 'icon': Icons.restaurant},
  ];
  
  // Sort options
  final List<String> _sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Distance: Nearest First',
    'Rating: High to Low',
  ];
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Mock search results
      final List<ProductModel> searchResults = [
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
      ];
      
      // Update search history
      if (!_recentSearches.any((search) => search['query'] == query)) {
        _recentSearches.insert(0, {
          'query': query,
          'timestamp': DateTime.now(),
        });
        
        // Limit to 5 recent searches
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
      
      setState(() {
        _products = searchResults;
        _isLoading = false;
      });
    });
  }
  
  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }
  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _priceRange = RangeValues(0, 500);
                            _selectedCategories = [];
                            _organicOnly = false;
                            _maxDistance = 50.0;
                            _sortBy = 'Relevance';
                          });
                          
                          // Also update the main state
                          setState(() {
                            _priceRange = RangeValues(0, 500);
                            _selectedCategories = [];
                            _organicOnly = false;
                            _maxDistance = 50.0;
                            _sortBy = 'Relevance';
                          });
                        },
                        child: Text('Reset'),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price range
                          _buildFilterSectionHeader('Price Range'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${_priceRange.start.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${_priceRange.end.toInt()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 500,
                            divisions: 50,
                            labels: RangeLabels(
                              '₹${_priceRange.start.toInt()}',
                              '₹${_priceRange.end.toInt()}',
                            ),
                            onChanged: (values) {
                              setSheetState(() {
                                _priceRange = values;
                              });
                              setState(() {
                                _priceRange = values;
                              });
                            },
                          ),
                          
                          Divider(height: 32.0),
                          
                          // Categories
                          _buildFilterSectionHeader('Categories'),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategories.contains(category['name']);
                              return FilterChip(
                                label: Text(category['name']),
                                selected: isSelected,
                                avatar: Icon(
                                  category['icon'],
                                  size: 18.0,
                                  color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                                ),
                                onSelected: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      _selectedCategories.add(category['name']);
                                    } else {
                                      _selectedCategories.remove(category['name']);
                                    }
                                  });
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category['name']);
                                    } else {
                                      _selectedCategories.remove(category['name']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          
                          Divider(height: 32.0),
                          
                          // Organic only
                          _buildFilterSectionHeader('Preferences'),
                          SwitchListTile(
                            title: Text('Organic Products Only'),
                            value: _organicOnly,
                            onChanged: (value) {
                              setSheetState(() {
                                _organicOnly = value;
                              });
                              setState(() {
                                _organicOnly = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          Divider(height: 32.0),
                          
                          // Distance
                          _buildFilterSectionHeader('Maximum Distance'),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _maxDistance,
                                  min: 5,
                                  max: 100,
                                  divisions: 19,
                                  label: '${_maxDistance.toInt()} km',
                                  onChanged: (value) {
                                    setSheetState(() {
                                      _maxDistance = value;
                                    });
                                    setState(() {
                                      _maxDistance = value;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                '${_maxDistance.toInt()} km',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          Divider(height: 32.0),
                          
                          // Sort by
                          _buildFilterSectionHeader('Sort By'),
                          Column(
                            children: _sortOptions.map((option) {
                              return RadioListTile<String>(
                                title: Text(option),
                                value: option,
                                groupValue: _sortBy,
                                onChanged: (value) {
                                  setSheetState(() {
                                    _sortBy = value!;
                                  });
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16.0),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Perform filtered search
                        _performSearch(_searchController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: Text('Apply Filters'),
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
  
  Widget _buildFilterSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search',
        // showBackButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for products...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                    ),
                    onSubmitted: _performSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                SizedBox(width: 12.0),
                InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Badge(
                      isLabelVisible: _selectedCategories.isNotEmpty || _organicOnly,
                      child: Icon(Icons.filter_list),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _buildInitialContent()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text('Clear All'),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            ...(_recentSearches.map((search) {
              return ListTile(
                leading: Icon(Icons.history),
                title: Text(search['query']),
                subtitle: Text(_formatTimeAgo(search['timestamp'])),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  _searchController.text = search['query'];
                  _performSearch(search['query']);
                },
                dense: true,
              );
            }).toList()),
            Divider(height: 32.0),
          ],
          
          // Popular categories
          Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: _categories.map((category) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategories = [category['name']];
                  });
                  _searchController.text = category['name'];
                  _performSearch(category['name']);
                },
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color: Theme.of(context).primaryColor,
                        size: 32.0,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 32.0),
          
          // Popular searches
          Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              'Organic Vegetables',
              'Fresh Fruits',
              'Basmati Rice',
              'Dairy Products',
              'Seasonal Produce',
              'Local Farmers',
            ].map((query) {
              return ActionChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              if (_organicOnly)
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text('Organic'),
                    onDeleted: () {
                      setState(() {
                        _organicOnly = false;
                      });
                      _performSearch(_searchController.text);
                    },
                    backgroundColor: Colors.green[100],
                  ),
                ),
              ..._selectedCategories.map((category) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(category),
                    onDeleted: () {
                      setState(() {
                        _selectedCategories.remove(category);
                      });
                      _performSearch(_searchController.text);
                    },
                  ),
                );
              }).toList(),
              if (_priceRange.start > 0 || _priceRange.end < 500)
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text('₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}'),
                    onDeleted: () {
                      setState(() {
                        _priceRange = RangeValues(0, 500);
                      });
                      _performSearch(_searchController.text);
                    },
                  ),
                ),
              if (_sortBy != 'Relevance')
                Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Chip(
                    label: Text(_sortBy),
                    onDeleted: () {
                      setState(() {
                        _sortBy = 'Relevance';
                      });
                      _performSearch(_searchController.text);
                    },
                  ),
                ),
            ],
          ),
        ),
        
        // Results info bar
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_products.length} results for "${_searchController.text}"',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _showFilterBottomSheet,
                icon: Icon(Icons.sort),
                label: Text('Sort & Filter'),
              ),
            ],
          ),
        ),
        
        // Results grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
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
  
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
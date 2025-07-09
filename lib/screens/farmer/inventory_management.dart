import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:flutter/services.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:intl/intl.dart';

class InventoryManagement extends StatefulWidget {
  @override
  _InventoryManagementState createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  
  // Inventory data
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Controllers for adding new product
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  
  // For filtering
  String _searchQuery = '';
  String _filterCategory = 'All Categories';
  late List<String> _categories = ['All Categories', 'Vegetables', 'Fruits', 'Grains', 'Dairy'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Default values
    _unitController.text = 'kg';
    _harvestDateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    // Load inventory data
    _loadInventoryData();
  }

  Future<void> _loadInventoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> items = await _firebaseService.getFarmerInventory();
      
      setState(() {
        _inventoryItems = items;
        _isLoading = false;
      });
      
      // Update categories list with actual categories from inventory
      _updateCategoriesList();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading inventory: $e';
        _isLoading = false;
      });
    }
  }

  void _updateCategoriesList() {
    // Get unique categories from inventory
    Set<String> categoriesSet = {'All Categories'};
    
    for (var item in _inventoryItems) {
      if (item.containsKey('category') && item['category'] != null) {
        categoriesSet.add(item['category']);
      }
    }
    
    setState(() {
      _categories = categoriesSet.toList();
    });
  }

  List<Map<String, dynamic>> get _filteredInventory {
    return _inventoryItems.where((item) {
      // Apply category filter
      if (_filterCategory != 'All Categories' && item['category'] != _filterCategory) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        String name = item['name']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      controller.text = DateFormat('dd MMM yyyy').format(picked);
    }
  }

  Future<void> _addInventoryItem() async {
    if (_productNameController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare item data
      Map<String, dynamic> item = {
        'name': _productNameController.text,
        'category': _categoryController.text,
        'quantity': int.parse(_quantityController.text),
        'unit': _unitController.text,
        'unitPrice': double.parse(_priceController.text),
        'totalValue': int.parse(_quantityController.text) * double.parse(_priceController.text),
        'harvestDate': _harvestDateController.text,
        'expiryDate': _expiryDateController.text,
        'status': 'In Stock',
      };
      
      bool success = await _firebaseService.addInventoryItem(item);
      
      if (success) {
        // Clear form
        _productNameController.clear();
        _categoryController.clear();
        _quantityController.clear();
        _priceController.clear();
        _harvestDateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
        _expiryDateController.clear();
        
        // Reload inventory
        await _loadInventoryData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Switch to Inventory tab
        _tabController.animateTo(0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateInventoryItem(String itemId, Map<String, dynamic> updates) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _firebaseService.updateInventoryItem(itemId, updates);
      
      if (success) {
        // Reload inventory
        await _loadInventoryData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInventoryItem(String itemId) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _firebaseService.deleteInventoryItem(itemId);
      
      if (success) {
        // Reload inventory
        await _loadInventoryData();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      floatingActionButton: IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadInventoryData,
            tooltip: 'Refresh inventory',
          ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'Add Product'),
              Tab(text: 'Summary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInventoryTab(),
                _buildAddProductTab(),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return _isLoading 
      ? Center(child: CircularProgressIndicator())
      : _errorMessage != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error loading inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(_errorMessage!),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInventoryData,
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8.0),
                    DropdownButton<String>(
                      value: _filterCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _filterCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filteredInventory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 72, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No inventory items found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _tabController.animateTo(1),
                              child: Text('Add Product'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredInventory.length,
                        itemBuilder: (context, index) {
                          final item = _filteredInventory[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12.0),
                            elevation: 2.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                item['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              subtitle: Text(
                                '${item['quantity']} ${item['unit']} • ₹${item['unitPrice']}/${item['unit']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              leading: Container(
                                width: 48.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(item['category']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item['category']),
                                  color: _getCategoryColor(item['category']),
                                ),
                              ),
                              trailing: Chip(
                                label: Text(
                                  item['status'] ?? 'In Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                                backgroundColor: item['status'] == 'Low Stock'
                                    ? Colors.orange
                                    : Colors.green,
                                padding: EdgeInsets.zero,
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _inventoryDetailItem(
                                            'Total Value',
                                            '₹${item['totalValue']}',
                                            Icons.monetization_on,
                                          ),
                                          _inventoryDetailItem(
                                            'Harvest Date',
                                            item['harvestDate'] ?? 'N/A',
                                            Icons.calendar_today,
                                          ),
                                          _inventoryDetailItem(
                                            'Expiry Date',
                                            item['expiryDate'] ?? 'N/A',
                                            Icons.timer,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16.0),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              _showEditItemDialog(context, item);
                                            },
                                            icon: Icon(Icons.edit, size: 16.0),
                                            label: Text('Edit'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.blue,
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          TextButton.icon(
                                            onPressed: () {
                                              _deleteInventoryItem(item['id']);
                                            },
                                            icon: Icon(Icons.delete, size: 16.0),
                                            label: Text('Delete'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }

  Widget _buildAddProductTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Product',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _productNameController,
            decoration: InputDecoration(
              labelText: 'Product Name*',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
          ),
          SizedBox(height: 12.0),
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: 'Category*',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              suffixIcon: PopupMenuButton<String>(
                icon: Icon(Icons.arrow_drop_down),
                onSelected: (value) {
                  _categoryController.text = value;
                },
                itemBuilder: (context) {
                  // Filter out "All Categories"
                  List<String> categories = _categories.where((c) => c != 'All Categories').toList();
                  
                  return categories.map((category) {
                    return PopupMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList();
                },
              ),
            ),
          ),
          SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity*',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    suffixIcon: PopupMenuButton<String>(
                      icon: Icon(Icons.arrow_drop_down),
                      onSelected: (value) {
                        _unitController.text = value;
                      },
                      itemBuilder: (context) {
                        return [
                          'kg',
                          'gm',
                          'liter',
                          'piece',
                          'dozen',
                          'quintal',
                        ].map((unit) {
                          return PopupMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.0),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'Price per unit (₹)*',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _harvestDateController,
                  decoration: InputDecoration(
                    labelText: 'Harvest Date',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () {
                        _selectDate(context, _harvestDateController);
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () {
                        _selectDate(context, _expiryDateController);
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addInventoryItem,
                  child: _isLoading 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Reset form
                    _productNameController.clear();
                    _categoryController.clear();
                    _quantityController.clear();
                    _priceController.clear();
                    _harvestDateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
                    _expiryDateController.clear();
                  },
                  child: Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          Text(
            '* Required fields',
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error loading inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInventoryData,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      );
    }
    
    // Calculate summary data
    Map<String, dynamic> summary = _calculateInventorySummary();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Summary',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          
          // Overview card
          _buildSummaryCard(
            'Inventory Overview',
            [
              {'label': 'Total Items', 'value': '${summary['totalItems']}'},
              {'label': 'Total Value', 'value': '₹${summary['totalValue']}'},
              {'label': 'Categories', 'value': '${summary['totalCategories']}'},
            ],
            color: Colors.blue,
            icon: Icons.inventory,
          ),
          
          SizedBox(height: 16.0),
          
          // Category breakdown
          Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.0),
          
          // Category cards
          ...(summary['categories'] as List<Map<String, dynamic>>).map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSummaryCard(
                category['name'],
                [
                  {'label': 'Items', 'value': '${category['count']}'},
                  {'label': 'Quantity', 'value': '${category['quantity']}'},
                  {'label': 'Value', 'value': '₹${category['value']}'},
                ],
                color: _getCategoryColor(category['name']),
                icon: _getCategoryIcon(category['name']),
              ),
            );
          }).toList(),
          
          SizedBox(height: 16.0),
          
          // Expiry alerts
          if (summary['expiringItems'] > 0) ...[
            Text(
              'Expiry Alerts',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.0),
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red[800],
                        size: 24.0,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items Expiring Soon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.red[800],
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'You have ${summary['expiringItems']} items that will expire within the next 7 days.',
                            style: TextStyle(
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          SizedBox(height: 16.0),
          
          // Low stock alerts
          if (summary['lowStockItems'] > 0) ...[
            Text(
              'Low Stock Alerts',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.0),
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: Colors.orange[800],
                        size: 24.0,
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.orange[800],
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'You have ${summary['lowStockItems']} items that are running low on stock.',
                            style: TextStyle(
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    List<Map<String, String>> items,
    {required Color color, required IconData icon}
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.0,
                  ),
                ),
                SizedBox(width: 16.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                return Column(
                  children: [
                    Text(
                      item['value']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      item['label']!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateInventorySummary() {
    int totalItems = _inventoryItems.length;
    double totalValue = 0;
    Set<String> categories = {};
    int expiringItems = 0;
    int lowStockItems = 0;
    
    // Category breakdown
    Map<String, Map<String, dynamic>> categoryBreakdown = {};
    
    for (var item in _inventoryItems) {
      // Calculate total value
      totalValue += (item['totalValue'] ?? 0).toDouble();
      
      // Track categories
      String category = item['category'] ?? 'Uncategorized';
      categories.add(category);
      
      // Initialize category data if needed
      if (!categoryBreakdown.containsKey(category)) {
        categoryBreakdown[category] = {
          'name': category,
          'count': 0,
          'quantity': 0,
          'value': 0,
        };
      }
      
      // Update category data
      categoryBreakdown[category]!['count'] = (categoryBreakdown[category]!['count'] ?? 0) + 1;
      categoryBreakdown[category]!['quantity'] = (categoryBreakdown[category]!['quantity'] ?? 0) + (item['quantity'] ?? 0);
      categoryBreakdown[category]!['value'] = (categoryBreakdown[category]!['value'] ?? 0) + (item['totalValue'] ?? 0);
      
      // Check for expiring items
      if (item['expiryDate'] != null) {
        try {
          DateTime expiryDate = DateFormat('dd MMM yyyy').parse(item['expiryDate']);
          DateTime now = DateTime.now();
          DateTime nextWeek = now.add(Duration(days: 7));
          
          if (expiryDate.isBefore(nextWeek)) {
            expiringItems++;
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
      
      // Check for low stock items
      if (item['status'] == 'Low Stock') {
        lowStockItems++;
      }
    }
    
    return {
      'totalItems': totalItems,
      'totalValue': totalValue.round(),
      'totalCategories': categories.length,
      'categories': categoryBreakdown.values.toList(),
      'expiringItems': expiringItems,
      'lowStockItems': lowStockItems,
    };
  }

  Widget _inventoryDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.0,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController nameController = TextEditingController(text: item['name']);
    TextEditingController categoryController = TextEditingController(text: item['category']);
    TextEditingController quantityController = TextEditingController(text: item['quantity'].toString());
    TextEditingController unitController = TextEditingController(text: item['unit']);
    TextEditingController priceController = TextEditingController(text: item['unitPrice'].toString());
    TextEditingController statusController = TextEditingController(text: item['status']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.0),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Price per unit (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12.0),
              DropdownButtonFormField(
                value: statusController.text,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['In Stock', 'Low Stock', 'Out of Stock'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  statusController.text = value.toString();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Calculate new total value
              double newPrice = double.tryParse(priceController.text) ?? 0;
              int newQuantity = int.tryParse(quantityController.text) ?? 0;
              double newTotalValue = newPrice * newQuantity;
              
              // Update item
              Map<String, dynamic> updates = {
                'name': nameController.text,
                'category': categoryController.text,
                'quantity': newQuantity,
                'unit': unitController.text,
                'unitPrice': newPrice,
                'totalValue': newTotalValue,
                'status': statusController.text,
              };
              
              Navigator.of(context).pop();
              _updateInventoryItem(item['id'], updates);
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'grains':
        return Colors.amber;
      case 'dairy':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'grains':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productNameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _harvestDateController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}
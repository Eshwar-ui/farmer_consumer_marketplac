import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/models/product_model.dart';
import 'package:farmer_consumer_marketplace/utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final double width;
  final double height;
  final bool showFarmerInfo;
  final bool showAddToCart;
  final bool isGridView;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.width = 160.0,
    this.height = 220.0,
    this.showFarmerInfo = false,
    this.showAddToCart = true,
    this.isGridView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridCard(context);
    } else {
      return _buildListCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                height: 120.0,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  image: product.imageUrls?.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrls!.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (product.imageUrls?.isEmpty ?? true)
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
              Expanded(
                child: Padding(
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
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.formatPricePerUnit(
                              product.price,
                              _getUnitString(product.unit),
                            ),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          Spacer(),
                          if (showAddToCart)
                            GestureDetector(
                              onTap: onAddToCart,
                              child: Container(
                                padding: EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Spacer(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  image: product.imageUrls?.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrls!.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrls?.isEmpty ?? true
                    ? Center(
                        child: Icon(
                          _getIconForCategory(product.category),
                          size: 36.0,
                          color: Colors.grey[400],
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 16.0),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (product.organic)
                          Container(
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
                      ],
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.formatPricePerUnit(
                            product.price,
                            _getUnitString(product.unit),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'Stock: ${product.quantity.toInt()} ${_getUnitString(product.unit)}',
                            style: TextStyle(
                              fontSize: 10.0,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Spacer(),
                        if (showAddToCart)
                          ElevatedButton(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              minimumSize: Size(0, 32.0),
                            ),
                            child: Text('Add'),
                          ),
                      ],
                    ),
                    if (showFarmerInfo) ...[
                      SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 12.0,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            'Farmer: John Doe',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8.0),
                          Icon(
                            Icons.location_on,
                            size: 12.0,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            product.location.split(',').first,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

class ProductCardSkeleton extends StatelessWidget {
  final bool isGridView;
  final double width;
  final double height;

  const ProductCardSkeleton({
    Key? key,
    this.isGridView = false,
    this.width = 160.0,
    this.height = 220.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridSkeleton();
    } else {
      return _buildListSkeleton();
    }
  }

  Widget _buildGridSkeleton() {
    return Container(
      width: width,
      height: height,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 120.0,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
              ),
            ),
            
            // Details skeleton
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.0,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    height: 10.0,
                    width: 80.0,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 14.0,
                        width: 60.0,
                        color: Colors.grey[300],
                      ),
                      Container(
                        height: 24.0,
                        width: 24.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    height: 10.0,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            SizedBox(width: 16.0),
            
            // Details skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.0,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8.0),
                  Container(
                    height: 12.0,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 4.0),
                  Container(
                    height: 12.0,
                    width: 200.0,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 16.0,
                        width: 80.0,
                        color: Colors.grey[300],
                      ),
                      Container(
                        height: 30.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4.0),
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
}

class ProductDetailCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final Function(double)? onQuantityChanged;
  final double initialQuantity;
  
  const ProductDetailCard({
    Key? key,
    required this.product,
    this.onAddToCart,
    this.onBuyNow,
    this.onQuantityChanged,
    this.initialQuantity = 1.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
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
            // Product name and organic badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (product.organic)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      'Organic',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.0),
            
            // Price and unit
            Row(
              children: [
                Text(
                  CurrencyFormatter.formatINR(product.price, decimalDigits: 0),
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  '/${_getUnitString(product.unit)}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            
            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              product.description,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16.0),
            
            // Details
            Text(
              'Details',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            _buildDetailItem('Category', _getCategoryName(product.category)),
            Divider(height: 16.0),
            _buildDetailItem('Quantity Available', '${product.quantity.toInt()} ${_getUnitString(product.unit)}'),
            Divider(height: 16.0),
            _buildDetailItem('Harvest Date', _formatDate(product.harvestDate)),
            Divider(height: 16.0),
            _buildDetailItem('Location', product.location),
            SizedBox(height: 24.0),
            
            // Quantity selector
            if (onQuantityChanged != null)
              QuantitySelector(
                initialValue: initialQuantity,
                minValue: 0.5,
                maxValue: product.quantity,
                step: _getStepSize(product.unit),
                unit: _getUnitString(product.unit),
                onChanged: onQuantityChanged!,
              ),
            SizedBox(height: 24.0),
            
            // Action buttons
            Row(
              children: [
                if (onAddToCart != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAddToCart,
                      icon: Icon(Icons.shopping_cart),
                      label: Text('Add to Cart'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                if (onAddToCart != null && onBuyNow != null)
                  SizedBox(width: 16.0),
                if (onBuyNow != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onBuyNow,
                      icon: Icon(Icons.flash_on),
                      label: Text('Buy Now'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _getCategoryName(ProductCategory category) {
    switch (category) {
      case ProductCategory.fruits:
        return 'Fruits';
      case ProductCategory.vegetables:
        return 'Vegetables';
      case ProductCategory.grains:
        return 'Grains';
      case ProductCategory.dairy:
        return 'Dairy';
      case ProductCategory.poultry:
        return 'Poultry';
      case ProductCategory.meat:
        return 'Meat';
      default:
        return 'Other';
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
  
  double _getStepSize(ProductUnit unit) {
    switch (unit) {
      case ProductUnit.kg:
      case ProductUnit.liter:
        return 0.5;
      case ProductUnit.gram:
        return 100;
      case ProductUnit.piece:
      case ProductUnit.dozen:
        return 1;
      case ProductUnit.quintal:
      case ProductUnit.ton:
        return 0.1;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class QuantitySelector extends StatefulWidget {
  final double initialValue;
  final double minValue;
  final double maxValue;
  final double step;
  final String unit;
  final Function(double) onChanged;
  
  const QuantitySelector({
    Key? key,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.step,
    required this.unit,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late double _quantity;
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _quantity = widget.initialValue;
    _controller = TextEditingController(text: _quantity.toString());
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _increment() {
    if (_quantity + widget.step <= widget.maxValue) {
      setState(() {
        _quantity += widget.step;
        _controller.text = _quantity.toString();
      });
      widget.onChanged(_quantity);
    }
  }
  
  void _decrement() {
    if (_quantity - widget.step >= widget.minValue) {
      setState(() {
        _quantity -= widget.step;
        _controller.text = _quantity.toString();
      });
      widget.onChanged(_quantity);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        Row(
          children: [
            InkWell(
              onTap: _decrement,
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(Icons.remove),
              ),
            ),
            SizedBox(width: 16.0),
            Container(
              width: 80.0,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newValue = double.tryParse(value);
                  if (newValue != null &&
                      newValue >= widget.minValue &&
                      newValue <= widget.maxValue) {
                    setState(() {
                      _quantity = newValue;
                    });
                    widget.onChanged(_quantity);
                  }
                },
              ),
            ),
            SizedBox(width: 8.0),
            Text(
              widget.unit,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 16.0),
            InkWell(
              onTap: _increment,
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Icon(Icons.add),
              ),
            ),
            Spacer(),
            Text(
              'Available: ${widget.maxValue} ${widget.unit}',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
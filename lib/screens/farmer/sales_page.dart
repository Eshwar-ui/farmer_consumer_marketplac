import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/screens/farmer/Total_Revenue_Widget.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:intl/intl.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allSales = [];

  @override
  void initState() {
    super.initState();
    _loadAllSales();
  }

  Future<void> _loadAllSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch all sales for the farmer
      final sales = await _firebaseService.getRecentSales(
        limit: 1000,
      ); // Adjust limit as needed
      setState(() {
        _allSales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading sales: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Sales'),
      body: RefreshIndicator(
        onRefresh: _loadAllSales,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TotalRevenueWidget(),
                const SizedBox(height: 18.0),
                _buildSummaryRow(),
                const SizedBox(height: 18.0),
                Text(
                  'All Sales',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                if (_isLoading)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage != null)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (_allSales.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _allSales.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final sale = _allSales[idx];
                      return _buildSaleCard(sale);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    if (_isLoading || _allSales.isEmpty) return SizedBox.shrink();
    final totalSales = _allSales.length;
    final bestProduct =
        _allSales
            .fold<Map<String, int>>({}, (map, sale) {
              final prod = sale['product'] ?? '-';
              map[prod] = (map[prod] ?? 0) + 1;
              return map;
            })
            .entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales',
                  style: TextStyle(fontSize: 13, color: Colors.green[900]),
                ),
                SizedBox(height: 2),
                Text(
                  '$totalSales',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Top Product',
                  style: TextStyle(fontSize: 13, color: Colors.green[900]),
                ),
                SizedBox(height: 2),
                Text(
                  '$bestProduct',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = sale['date'] ?? '-';
    final product = sale['product'] ?? '-';
    final quantity = sale['quantity'] ?? '-';
    final price = sale['price'] ?? '-';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.shopping_cart,
                color: Colors.green[700],
                size: 28,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Qty: $quantity',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            SizedBox(height: 18),
            Text(
              'No sales found.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your sales will appear here once you start selling products.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

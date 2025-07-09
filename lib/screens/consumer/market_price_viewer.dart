import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';

class MarketPriceViewer extends StatefulWidget {
  @override
  _MarketPriceViewerState createState() => _MarketPriceViewerState();
}

class _MarketPriceViewerState extends State<MarketPriceViewer> {
  bool _isLoading = false;
  String _selectedCrop = 'Tomatoes';
  String _selectedLocation = 'All India';
  String _selectedTimeframe = '1 Month';
  
  // Mock data for price trends
  List<Map<String, dynamic>> _priceData = [];
  
  // Mock data for market comparisons
  List<Map<String, dynamic>> _marketComparisonData = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Generate mock price trend data
      final now = DateTime.now();
      final List<Map<String, dynamic>> priceData = [];
      
      for (int i = 30; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        
        // Generate a price with some fluctuation
        double basePrice = 0;
        switch (_selectedCrop) {
          case 'Tomatoes':
            basePrice = 40.0;
            break;
          case 'Potatoes':
            basePrice = 25.0;
            break;
          case 'Onions':
            basePrice = 35.0;
            break;
          case 'Rice':
            basePrice = 80.0;
            break;
          case 'Wheat':
            basePrice = 30.0;
            break;
          default:
            basePrice = 40.0;
        }
        
        // Add some random fluctuation
        final random = (date.day % 5) * 2.0;
        final trendFactor = (30 - i) * 0.15; // Slight upward trend
        final price = basePrice + random + trendFactor;
        
        priceData.add({
          'date': date,
          'price': price,
        });
      }
      
      // Generate market comparison data
      final List<Map<String, dynamic>> marketData = [
        {'market': 'APMC', 'price': 45.0},
        {'market': 'Local Market', 'price': 50.0},
        {'market': 'City Market', 'price': 55.0},
        {'market': 'Wholesale', 'price': 38.0},
        {'market': 'Online Platform', 'price': 60.0},
      ];
      
      setState(() {
        _priceData = priceData;
        _marketComparisonData = marketData;
        _isLoading = false;
      });
    });
  }
  
  void _applyFilters() {
    // Reload data with new filters
    _loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(
      //   title: 'Market Prices',
      //   // showBackButton: true,
      // ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter section
                  _buildFilterSection(),
                  
                  SizedBox(height: 24.0),
                  
                  // Price trend chart
                  _buildPriceTrendChart(),
                  
                  SizedBox(height: 24.0),
                  
                  // Market comparison
                  _buildMarketComparison(),
                  
                  SizedBox(height: 24.0),
                  
                  // Price insights
                  _buildPriceInsights(),
                  
                  SizedBox(height: 24.0),
                  
                  // Popular products
                  _buildPopularProducts(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildFilterSection() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            
            // Crop dropdown
            _buildDropdown(
              label: 'Crop',
              value: _selectedCrop,
              items: ['Tomatoes', 'Potatoes', 'Onions', 'Rice', 'Wheat'],
              onChanged: (value) {
                setState(() {
                  _selectedCrop = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            
            // Location dropdown
            _buildDropdown(
              label: 'Location',
              value: _selectedLocation,
              items: [
                'All India',
                'Delhi',
                'Mumbai',
                'Kolkata',
                'Chennai',
                'Bangalore',
              ],
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            
            // Timeframe dropdown
            _buildDropdown(
              label: 'Timeframe',
              value: _selectedTimeframe,
              items: ['1 Week', '1 Month', '3 Months', '6 Months', '1 Year'],
              onChanged: (value) {
                setState(() {
                  _selectedTimeframe = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            
            // Apply filters button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceTrendChart() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedCrop Price Trend',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    _selectedTimeframe,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Container(
              height: 200.0,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      // tooltipBgColor: Colors.white.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = _priceData[touchedSpot.x.toInt()]['date'] as DateTime;
                          final price = touchedSpot.y;
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n',
                            TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '₹ ${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= _priceData.length || value < 0) {
                            return const SizedBox.shrink();
                          }
                          
                          // Show fewer labels to avoid crowding
                          if (_priceData.length > 10) {
                            if (value.toInt() % (_priceData.length ~/ 5) != 0) {
                              return const SizedBox.shrink();
                            }
                          }
                          
                          final date = _priceData[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              '₹${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  minX: 0,
                  maxX: (_priceData.length - 1).toDouble(),
                  minY: _getMinPrice() * 0.9,
                  maxY: _getMaxPrice() * 1.1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(_priceData.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          _priceData[index]['price']
                        );
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
                // swapAnimationDuration: Duration(milliseconds: 400),
              ),
            ),
            SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceStat(
                  'Min Price',
                  '₹ ${_getMinPrice().toStringAsFixed(2)}',
                  Icons.arrow_downward,
                  Colors.red,
                ),
                _buildPriceStat(
                  'Avg Price',
                  '₹ ${_getAvgPrice().toStringAsFixed(2)}',
                  Icons.stacked_line_chart,
                  Colors.blue,
                ),
                _buildPriceStat(
                  'Max Price',
                  '₹ ${_getMaxPrice().toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  Colors.green,
                ),
                _buildPriceStat(
                  'Change',
                  '${_getPriceChange() > 0 ? '+' : ''}${_getPriceChange().toStringAsFixed(2)}%',
                  _getPriceChange() > 0 ? Icons.trending_up : Icons.trending_down,
                  _getPriceChange() > 0 ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  double _getMinPrice() {
    if (_priceData.isEmpty) return 0;
    return _priceData.map((item) => item['price'] as double).reduce((a, b) => a < b ? a : b);
  }
  
  double _getMaxPrice() {
    if (_priceData.isEmpty) return 0;
    return _priceData.map((item) => item['price'] as double).reduce((a, b) => a > b ? a : b);
  }
  
  double _getAvgPrice() {
    if (_priceData.isEmpty) return 0;
    final sum = _priceData.fold<double>(0, (sum, item) => sum + (item['price'] as double));
    return sum / _priceData.length;
  }
  
  double _getPriceChange() {
    if (_priceData.length < 2) return 0;
    final firstPrice = _priceData.first['price'] as double;
    final lastPrice = _priceData.last['price'] as double;
    
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }
  
  Widget _buildPriceStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16.0,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMarketComparison() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Comparison',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              height: 200.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxMarketPrice() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      // tooltipBgColor: Colors.white.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_marketComparisonData[group.x.toInt()]['market']}\n',
                          TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '₹ ${rod.toY.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= _marketComparisonData.length || value < 0) {
                            return const SizedBox.shrink();
                          }
                          
                          final marketName = _marketComparisonData[value.toInt()]['market'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              marketName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              '₹${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      left: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: List.generate(_marketComparisonData.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _marketComparisonData[index]['price'],
                          color: Colors.green,
                          width: 20,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                swapAnimationDuration: Duration(milliseconds: 400),
              ),
            ),
            SizedBox(height: 16.0),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.amber[700],
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Online platforms are currently offering the highest prices for $_selectedCrop. Consider checking various markets for the best deals.',
                      style: TextStyle(
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _getMaxMarketPrice() {
    if (_marketComparisonData.isEmpty) return 0;
    return _marketComparisonData.map((item) => item['price'] as double).reduce((a, b) => a > b ? a : b);
  }
  
  Widget _buildPriceInsights() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Insights',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            _buildInsightItem(
              'Prices are expected to rise by 5% next week due to decreased supply.',
              Icons.trending_up,
              Colors.red,
            ),
            SizedBox(height: 12.0),
            _buildInsightItem(
              'Current price is 10% higher than last month.',
              Icons.trending_up,
              Colors.red,
            ),
            SizedBox(height: 12.0),
            _buildInsightItem(
              'Best time to buy: Early morning at wholesale markets.',
              Icons.access_time,
              Colors.blue,
            ),
            SizedBox(height: 12.0),
            _buildInsightItem(
              'Prices in ${_selectedLocation == 'All India' ? 'Southern regions' : _selectedLocation} are lower than the national average.',
              Icons.location_on,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInsightItem(
    String text,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16.0,
          ),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
  
  Widget _buildPopularProducts() {
    // List of popular products with their price trends
    final popularProducts = [
      {
        'name': 'Tomatoes',
        'trend': 'up',
        'percentage': 15.0,
      },
      {
        'name': 'Potatoes',
        'trend': 'down',
        'percentage': 5.0,
      },
      {
        'name': 'Onions',
        'trend': 'up',
        'percentage': 10.0,
      },
      {
        'name': 'Rice',
        'trend': 'stable',
        'percentage': 0.0,
      },
      {
        'name': 'Wheat',
        'trend': 'down',
        'percentage': 3.0,
      },
    ];
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Products',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            ...popularProducts.map((product) {
              final isUp = product['trend'] == 'up';
              final isStable = product['trend'] == 'stable';
              final color = isUp ? Colors.red : (isStable ? Colors.blue : Colors.green);
              final icon = isUp ? Icons.trending_up : (isStable ? Icons.trending_flat : Icons.trending_down);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCrop = product['name'] as String;
                  });
                  _loadData();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          product['name'] as String,
                          style: TextStyle(
                            fontWeight: product['name'] == _selectedCrop ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: color,
                              size: 16.0,
                            ),
                            SizedBox(width: 4.0),
                            Text(
                              '${isStable ? '' : (isUp ? '+' : '-')}${product['percentage']}%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: () {
                // Navigate to price comparison screen
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 44.0),
              ),
              child: Text('View All Products'),
            ),
          ],
        ),
      ),
    );
  }
}
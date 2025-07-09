import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:farmer_consumer_marketplace/services/ml/price_prediction.dart';

class PriceAnalysis extends StatefulWidget {
  @override
  _PriceAnalysisState createState() => _PriceAnalysisState();
}

class _PriceAnalysisState extends State<PriceAnalysis> {
  bool _isLoading = false;
  String _selectedCrop = 'Tomatoes';
  String _selectedLocation = 'Nashik, Maharashtra';
  String _selectedTimeframe = '1 Month';
  
  // Mock data for price trends
  List<PricePoint> _priceData = [];
  
  // Mock data for price comparisons
  List<MarketPrice> _marketPrices = [];
  
  // Mock price prediction
  PricePrediction? _pricePrediction;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 800));

    // Generate mock price trend data
    final now = DateTime.now();
    _priceData = List.generate(30, (index) {
      final date = now.subtract(Duration(days: 29 - index));
      // Simulate some price fluctuation
      final basePrice = 40.0;
      final randomFactor = (index % 7) * 2.0;
      final trendFactor = index * 0.2;
      final price = basePrice + randomFactor + trendFactor;
      
      return PricePoint(date, price);
    });

    // Generate mock market price comparison data
    _marketPrices = [
      MarketPrice('APMC Nashik', 45.0),
      MarketPrice('Local Market', 50.0),
      MarketPrice('City Market', 55.0),
      MarketPrice('Wholesale', 38.0),
      MarketPrice('Online Platform', 60.0),
    ];

    // Generate mock price prediction
    _pricePrediction = PricePrediction(
      crop: _selectedCrop,
      location: _selectedLocation,
      predictedMinPrice: 42.0,
      predictedAvgPrice: 48.0,
      predictedMaxPrice: 55.0,
      historicalMinPrice: 38.0,
      historicalAvgPrice: 45.0,
      historicalMaxPrice: 52.0,
      factors: {
        'Supply Level': 0.7,
        'Demand Level': 0.8,
        'Rainfall': 120.0,
        'Season': 'Summer',
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _updateData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Update data based on selected filters
      // In a real app, this would make API calls with the selected parameters
      
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter section
                  _buildFilterSection(),
                  
                  const SizedBox(height: 24.0),
                  
                  // Price trend chart
                  _buildPriceTrendChart(),
                  
                  const SizedBox(height: 24.0),
                  
                  // Price prediction
                  _buildPricePrediction(),
                  
                  const SizedBox(height: 24.0),
                  
                  // Market price comparison
                  _buildMarketPriceComparison(),
                  
                  const SizedBox(height: 24.0),
                  
                  // Price factors
                  _buildPriceFactors(),
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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Crop',
                    value: _selectedCrop,
                    items: ['Tomatoes', 'Potatoes', 'Onions', 'Rice', 'Wheat'],
                    onChanged: (value) {
                      setState(() {
                        _selectedCrop = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildDropdown(
                    label: 'Location',
                    value: _selectedLocation,
                    items: [
                      'Nashik, Maharashtra',
                      'Pune, Maharashtra',
                      'Delhi NCR',
                      'Bangalore, Karnataka',
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Timeframe',
                    value: _selectedTimeframe,
                    items: ['1 Week', '1 Month', '3 Months', '6 Months', '1 Year'],
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeframe = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateData,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text('Apply Filters'),
                  ),
                ),
              ],
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
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price Trend',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    'Last $_selectedTimeframe',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 250.0,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      // tooltipBgColor: Colors.white.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final date = _priceData[touchedSpot.x.toInt()].date;
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
                          
                          final date = _priceData[value.toInt()].date;
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
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Price (₹ per kg)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
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
                        reservedSize: 40,
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
                          _priceData[index].price,
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
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChartStat(
                  'Avg Price',
                  '₹ 45',
                  Icons.stacked_line_chart,
                  Colors.blue,
                ),
                _buildChartStat(
                  'Min Price',
                  '₹ 38',
                  Icons.arrow_downward,
                  Colors.red,
                ),
                _buildChartStat(
                  'Max Price',
                  '₹ 52',
                  Icons.arrow_upward,
                  Colors.green,
                ),
                _buildChartStat(
                  'Volatility',
                  '8.5%',
                  Icons.show_chart,
                  Colors.orange,
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
    return _priceData.map((point) => point.price).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    if (_priceData.isEmpty) return 0;
    return _priceData.map((point) => point.price).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildChartStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
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
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
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

  Widget _buildPricePrediction() {
    if (_pricePrediction == null) {
      return SizedBox.shrink();
    }

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
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Price Prediction (Next 7 Days)',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPredictionColumn(
                  'Min',
                  _pricePrediction!.predictedMinPrice,
                  _pricePrediction!.historicalMinPrice,
                ),
                _buildDivider(),
                _buildPredictionColumn(
                  'Average',
                  _pricePrediction!.predictedAvgPrice,
                  _pricePrediction!.historicalAvgPrice,
                ),
                _buildDivider(),
                _buildPredictionColumn(
                  'Max',
                  _pricePrediction!.predictedMaxPrice,
                  _pricePrediction!.historicalMaxPrice,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Price is expected to increase by 6.7% in the next week due to reduced supply and increased demand.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14.0,
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

  Widget _buildDivider() {
    return Container(
      height: 70.0,
      width: 1.0,
      color: Colors.grey[300],
    );
  }

  Widget _buildPredictionColumn(
    String label,
    double predictedPrice,
    double historicalPrice,
  ) {
    final percentageChange =
        ((predictedPrice - historicalPrice) / historicalPrice) * 100;
    final isIncrease = percentageChange >= 0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          '₹ ${predictedPrice.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
              color: isIncrease ? Colors.green : Colors.red,
              size: 14.0,
            ),
            Text(
              '${percentageChange.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: isIncrease ? Colors.green : Colors.red,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketPriceComparison() {
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
            Text(
              'Market Price Comparison',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
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
                          '${_marketPrices[group.x.toInt()].market}\n',
                          TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '₹${_marketPrices[group.x.toInt()].price.toStringAsFixed(2)}',
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
                          if (value.toInt() >= _marketPrices.length || value < 0) {
                            return const SizedBox.shrink();
                          }
                          
                          // Abbreviate market names if needed
                          String market = _marketPrices[value.toInt()].market;
                          if (market.length > 12) {
                            final parts = market.split(' ');
                            if (parts.length > 1) {
                              market = parts.map((part) => part.length > 3 ? part.substring(0, 3) : part).join(' ');
                            } else {
                              market = market.substring(0, 10) + '...';
                            }
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              market,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        reservedSize: 30,
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
                        reservedSize: 40,
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
                  barGroups: List.generate(_marketPrices.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _marketPrices[index].price,
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
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber[700],
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Online platforms are currently offering the best prices for $_selectedCrop.',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 14.0,
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
    if (_marketPrices.isEmpty) return 0;
    return _marketPrices.map((price) => price.price).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildPriceFactors() {
    if (_pricePrediction == null || _pricePrediction!.factors.isEmpty) {
      return SizedBox.shrink();
    }

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
            Text(
              'Price Influencing Factors',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            ..._pricePrediction!.factors.entries.map((entry) {
              return _buildFactorItem(
                entry.key,
                entry.value.toString(),
                _getFactorIcon(entry.key),
                _getFactorColor(entry.key),
              );
            }).toList(),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to detailed market analysis
              },
              icon: Icon(Icons.analytics),
              label: Text('View Detailed Analysis'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFactorIcon(String factor) {
    switch (factor) {
      case 'Supply Level':
        return Icons.inventory;
      case 'Demand Level':
        return Icons.people;
      case 'Rainfall':
        return Icons.water_drop;
      case 'Season':
        return Icons.calendar_today;
      default:
        return Icons.info_outline;
    }
  }

  Color _getFactorColor(String factor) {
    switch (factor) {
      case 'Supply Level':
        return Colors.blue;
      case 'Demand Level':
        return Colors.orange;
      case 'Rainfall':
        return Colors.cyan;
      case 'Season':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint(this.date, this.price);
}

class MarketPrice {
  final String market;
  final double price;

  MarketPrice(this.market, this.price);
}
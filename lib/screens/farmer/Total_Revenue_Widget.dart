import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class TotalRevenueWidget extends StatefulWidget {
  @override
  _TotalRevenueWidgetState createState() => _TotalRevenueWidgetState();
}

enum RevenuePeriod { day, week, month, year }

class _TotalRevenueWidgetState extends State<TotalRevenueWidget>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String? _errorMessage;

  // Revenue data
  double _totalRevenue = 0;
  double _prevRevenue = 0;
  List<Map<String, dynamic>> _chartData = [];
  RevenuePeriod _selectedPeriod = RevenuePeriod.month;
  late AnimationController _animationController;
  late Animation<double> _revenueAnimation;

  static const Map<RevenuePeriod, String> _periodLabels = {
    RevenuePeriod.day: 'Today',
    RevenuePeriod.week: 'This Week',
    RevenuePeriod.month: 'This Month',
    RevenuePeriod.year: 'This Year',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _revenueAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadRevenueData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRevenueData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final revenueData = await _firebaseService.getTotalRevenueData();
      if (!mounted) return;
      if (revenueData['hasData'] == true) {
        List<Map<String, dynamic>> allOrders = revenueData['orders'] ?? [];
        DateTime now = DateTime.now();
        List<Map<String, dynamic>> filteredOrders = [];
        List<Map<String, dynamic>> chartData = [];
        double total = 0.0;
        double prevTotal = _totalRevenue;
        if (_selectedPeriod == RevenuePeriod.day) {
          filteredOrders =
              allOrders.where((order) {
                if (order['orderDate'] == null) return false;
                DateTime date = DateFormat(
                  'yyyy-MM-dd',
                ).parse(order['orderDate']);
                return date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              }).toList();
          total = filteredOrders.fold(
            0.0,
            (sum, order) => sum + (order['totalAmount'] ?? 0.0),
          );
          chartData = [
            {'label': DateFormat('dd MMM').format(now), 'amount': total},
          ];
        } else if (_selectedPeriod == RevenuePeriod.week) {
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          filteredOrders =
              allOrders.where((order) {
                if (order['orderDate'] == null) return false;
                DateTime date = DateFormat(
                  'yyyy-MM-dd',
                ).parse(order['orderDate']);
                return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
                    date.isBefore(now.add(Duration(days: 1)));
              }).toList();
          Map<String, double> daily = {};
          for (var order in filteredOrders) {
            DateTime date = DateFormat('yyyy-MM-dd').parse(order['orderDate']);
            String label = DateFormat('EEE').format(date);
            daily[label] =
                (daily[label] ?? 0.0) + (order['totalAmount'] ?? 0.0);
          }
          total = filteredOrders.fold(
            0.0,
            (sum, order) => sum + (order['totalAmount'] ?? 0.0),
          );
          chartData =
              daily.entries
                  .map((e) => {'label': e.key, 'amount': e.value})
                  .toList();
        } else if (_selectedPeriod == RevenuePeriod.month) {
          total = double.parse(revenueData['totalRevenue'].toString());
          chartData =
              (revenueData['monthlyRevenue'] as List).map((item) {
                return {
                  'label': item['month'],
                  'amount': double.parse(item['amount'].toString()),
                };
              }).toList();
        } else if (_selectedPeriod == RevenuePeriod.year) {
          Map<String, double> yearly = {};
          for (var order in allOrders) {
            if (order['orderDate'] == null) continue;
            DateTime date = DateFormat('yyyy-MM-dd').parse(order['orderDate']);
            String year = date.year.toString();
            yearly[year] =
                (yearly[year] ?? 0.0) + (order['totalAmount'] ?? 0.0);
          }
          total = yearly.values.fold(0.0, (a, b) => a + b);
          chartData =
              yearly.entries
                  .map((e) => {'label': e.key, 'amount': e.value})
                  .toList();
        }
        setState(() {
          _prevRevenue = prevTotal;
          _totalRevenue = total;
          _chartData = chartData;
          _isLoading = false;
        });
        _revenueAnimation = Tween<double>(begin: prevTotal, end: total).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
        _animationController.forward(from: 0);
      } else {
        setState(() {
          _errorMessage = revenueData['message'] ?? 'No revenue data available';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading revenue data: $e';
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(RevenuePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadRevenueData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0ffe0), Color(0xFFf8fff8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.0),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _periodLabels[_selectedPeriod]!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _revenueAnimation,
                      builder: (context, child) {
                        return Text(
                          '₹${NumberFormat('#,##0.00').format(_revenueAnimation.value)}',
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 18.0),
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/farm_empty.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.analytics_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadRevenueData,
                        icon: Icon(Icons.refresh, color: Colors.green),
                        label: Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_chartData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/farm_empty.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No revenue data to display for this period.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 220.0,
                padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                child: _buildBarChart(),
              ),
            SizedBox(height: 18.0),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.green.withOpacity(0.08),
                  //     blurRadius: 8,
                  //     offset: Offset(0, 2),
                  //   ),
                  // ],
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: CupertinoSegmentedControl<RevenuePeriod>(
                  groupValue: _selectedPeriod,
                  onValueChanged: _onPeriodChanged,
                  children: const {
                    RevenuePeriod.day: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RevenuePeriod.week: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Week',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RevenuePeriod.month: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    RevenuePeriod.year: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Year',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  },
                  selectedColor: Colors.green,
                  unselectedColor: Colors.white,
                  borderColor: Colors.green,
                  pressedColor: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    double maxValue = 0;
    for (var item in _chartData) {
      if (item['amount'] > maxValue) {
        maxValue = item['amount'];
      }
    }
    maxValue = maxValue * 1.1;
    if (maxValue == 0) {
      maxValue = 100;
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = _chartData[groupIndex]['label'];
              double amount = _chartData[groupIndex]['amount'];
              return BarTooltipItem(
                '$label\n₹${NumberFormat('#,##0.00').format(amount)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
          handleBuiltInTouches: true,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < _chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _chartData[index]['label'],
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 || value == maxValue / 2 || value == maxValue) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      '₹${NumberFormat('#,##0').format(value)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_chartData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _chartData[index]['amount'],
                color: Colors.green,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

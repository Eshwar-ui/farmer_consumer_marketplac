import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/services/firebase_service.dart';
import 'package:fl_chart/fl_chart.dart';

class TotalRevenueWidget extends StatefulWidget {
  @override
  _TotalRevenueWidgetState createState() => _TotalRevenueWidgetState();
}

class _TotalRevenueWidgetState extends State<TotalRevenueWidget> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // Revenue data
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _monthlyRevenue = [];
  
  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }
  
  Future<void> _loadRevenueData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final revenueData = await _firebaseService.getTotalRevenueData();
      
      setState(() {
        if (revenueData['hasData'] == true) {
          // Ensure totalRevenue is a double
          _totalRevenue = double.parse(revenueData['totalRevenue'].toString());
          
          // Ensure each monthly amount is a double
          _monthlyRevenue = (revenueData['monthlyRevenue'] as List).map((item) {
            return {
              'month': item['month'],
              'amount': double.parse(item['amount'].toString()),
            };
          }).toList();
        } else {
          _errorMessage = revenueData['message'] ?? 'No revenue data available';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading revenue data: $e';
        _isLoading = false;
      });
      print('Error in Total Revenue Widget: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Total Revenue',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    )
                  : Text(
                      '₹${NumberFormat('#,##0.00').format(_totalRevenue)}',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
              ],
            ),
            SizedBox(height: 8.0),
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
                      Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadRevenueData,
                        child: Text('Try Again'),
                      )
                    ],
                  ),
                ),
              )
            else if (_monthlyRevenue.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No revenue data to display',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200.0,
                child: _buildBarChart(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBarChart() {
    // Find max value for chart scaling
    double maxValue = 0;
    for (var month in _monthlyRevenue) {
      if (month['amount'] > maxValue) {
        maxValue = month['amount'];
      }
    }
    
    // Add 10% padding to max value
    maxValue = maxValue * 1.1;
    
    // If max value is 0, set a default value
    if (maxValue == 0) {
      maxValue = 100;
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String month = _monthlyRevenue[groupIndex]['month'];
              double amount = _monthlyRevenue[groupIndex]['amount'];
              return BarTooltipItem(
                '$month\n₹${NumberFormat('#,##0.00').format(amount)}',
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
                if (index >= 0 && index < _monthlyRevenue.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _monthlyRevenue[index]['month'],
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
                // Only show a few values on y-axis
                if (value == 0 || value == maxValue / 2 || value == maxValue) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      '₹${NumberFormat('#,##0').format(value)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(_monthlyRevenue.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _monthlyRevenue[index]['amount'],
                color: Colors.green,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
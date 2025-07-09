import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:farmer_consumer_marketplace/utils/app_colors.dart';

class PriceChart extends StatelessWidget {
  final List<Map<String, dynamic>> priceHistory;

  const PriceChart({
    Key? key,
    required this.priceHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (priceHistory.isEmpty) {
      return Center(child: Text('No price data available'));
    }

    // Sort data chronologically
    final sortedData = List<Map<String, dynamic>>.from(priceHistory);
    sortedData.sort((a, b) {
      final DateTime dateA = DateFormat('yyyy-MM-dd').parse(a['date'].toString());
      final DateTime dateB = DateFormat('yyyy-MM-dd').parse(b['date'].toString());
      return dateA.compareTo(dateB);
    });

    // Find min and max prices for y-axis
    double minPrice = double.infinity;
    double maxPrice = 0;
    
    for (var point in sortedData) {
      final price = double.parse(point['price'].toString());
      if (price < minPrice) minPrice = price;
      if (price > maxPrice) maxPrice = price;
    }
    
    // Add some padding to min/max
    minPrice = (minPrice * 0.9).floorToDouble();
    maxPrice = (maxPrice * 1.1).ceilToDouble();

    // Create spot data
    final List<FlSpot> spots = [];
    
    for (int i = 0; i < sortedData.length; i++) {
      final price = double.parse(sortedData[i]['price'].toString());
      spots.add(FlSpot(i.toDouble(), price));
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxPrice - minPrice) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          // titlesData: FlTitlesData(
          //   bottomTitles: SideTitles(
          //     showTitles: true,
          //     reservedSize: 30,
          //     getTextStyles: (context, value) => const TextStyle(
          //       color: Colors.grey,
          //       fontSize: 10,
          //     ),
          //     showTitles: (value) {
          //       // Show dates at intervals
          //       int index = value.toInt();
          //       if (index >= 0 && index < sortedData.length) {
          //         // Show every 7th day
          //         if (index % 7 == 0 || index == sortedData.length - 1) {
          //           final dateStr = sortedData[index]['date'].toString();
          //           try {
          //             final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          //             return DateFormat('dd MMM').format(date);
          //           } catch (e) {
          //             return '';
          //           }
          //         }
          //       }
          //       return '';
          //     },
          //     margin: 10,
          //   ),
          //   leftTitles: SideTitles(
          //     showTitles: true,
          //     getTextStyles: (context, value) => const TextStyle(
          //       color: Colors.grey,
          //       fontSize: 10,
          //     ),
          //     getTitles: (value) {
          //       return '₹${value.toInt()}';
          //     },
          //     reservedSize: 40,
          //     margin: 10,
          //   ),
          //   rightTitles: SideTitles(showTitles: false),
          //   topTitles: SideTitles(showTitles: false),
          // ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          minX: 0,
          maxX: (sortedData.length - 1).toDouble(),
          minY: minPrice,
          maxY: maxPrice,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color:AppColors.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: 
                  AppColors.primaryColor.withOpacity(0.3),
                  // AppColors.primaryColor.withOpacity(0.0),]
                // ,
                // gradientFrom: Offset(0, 0),
                // gradientTo: Offset(0, 1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: Colors.blueAccent,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index >= 0 && index < sortedData.length) {
                    final dateStr = sortedData[index]['date'].toString();
                    final price = barSpot.y;
                    
                    try {
                      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                      final formattedDate = DateFormat('dd MMM, yyyy').format(date);
                      return LineTooltipItem(
                        '$formattedDate\n₹${price.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    } catch (e) {
                      return LineTooltipItem(
                        '₹${price.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    }
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
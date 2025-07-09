import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PricePoint {
  final DateTime date;
  final double price;

  PricePoint(this.date, this.price);
}

class PriceChart extends StatefulWidget {
  final List<PricePoint> data;
  final String title;
  final String? subtitle;
  final bool animate;
  final bool showGrid;
  final bool showLegend;
  final bool showLabels;
  final String? yAxisTitle;
  final String? xAxisTitle;
  final double height;
  final Color lineColor;
  final bool showAreaFill;
  final bool allowZoom;
  final int? decimalDigits;

  const PriceChart({
    Key? key,
    required this.data,
    this.title = 'Price Trend',
    this.subtitle,
    this.animate = true,
    this.showGrid = true,
    this.showLegend = false,
    this.showLabels = true,
    this.yAxisTitle,
    this.xAxisTitle,
    this.height = 250.0,
    this.lineColor = Colors.blue,
    this.showAreaFill = true,
    this.allowZoom = false,
    this.decimalDigits,
  }) : super(key: key);

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  final tooltipKey = GlobalKey();
  PricePoint? selectedPoint;
  double? minY, maxY;
  bool isTooltipVisible = false;
  Offset? tooltipPosition;
  
  @override
  void initState() {
    super.initState();
    _updateMinMaxValues();
  }

  @override
  void didUpdateWidget(PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _updateMinMaxValues();
    }
  }

  void _updateMinMaxValues() {
    if (widget.data.isEmpty) {
      minY = 0;
      maxY = 100;
      return;
    }

    final prices = widget.data.map((e) => e.price).toList();
    minY = prices.reduce((a, b) => a < b ? a : b);
    maxY = prices.reduce((a, b) => a > b ? a : b);
    
    // Add some padding to the min/max values for better visualization
    final range = maxY! - minY!;
    minY = minY! - (range * 0.1).clamp(1, double.infinity);
    maxY = maxY! + (range * 0.1).clamp(1, double.infinity);
    
    // Ensure minY is never negative for most price charts
    minY = minY! < 0 ? 0 : minY;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title.isNotEmpty || widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title.isNotEmpty)
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: widget.data.isEmpty
                ? const Center(child: Text('No data available'))
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16, top: 8),
                        child: LineChart(
                          LineChartData(
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                // tooltipBgColor: Colors.white.withOpacity(0.8),
                                tooltipBorder: const BorderSide(color: Colors.grey),
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final date = widget.data[spot.x.toInt()].date;
                                    final price = spot.y;
                                    
                                    return LineTooltipItem(
                                      '${DateFormat('MMM d, yyyy').format(date)}\n',
                                      const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '₹${price.toStringAsFixed(widget.decimalDigits ?? 0)}',
                                          style: TextStyle(
                                            color: widget.lineColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                if (event is FlTapUpEvent || event is FlPanEndEvent) {
                                  setState(() {
                                    isTooltipVisible = false;
                                  });
                                  return;
                                }
                                
                                if (touchResponse == null || touchResponse.lineBarSpots == null || touchResponse.lineBarSpots!.isEmpty) {
                                  setState(() {
                                    isTooltipVisible = false;
                                  });
                                  return;
                                }
                                
                                final spot = touchResponse.lineBarSpots!.first;
                                if (spot.x.toInt() >= 0 && spot.x.toInt() < widget.data.length) {
                                  setState(() {
                                    selectedPoint = widget.data[spot.x.toInt()];
                                    tooltipPosition = event is FlPanUpdateEvent 
                                        ? event.localPosition 
                                        : null;
                                    isTooltipVisible = true;
                                  });
                                }
                              },
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: widget.showLabels,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= widget.data.length || value.toInt() < 0) {
                                      return const SizedBox.shrink();
                                    }
                                    
                                    // Show fewer labels to avoid overcrowding
                                    if (widget.data.length > 10) {
                                      if (value.toInt() % (widget.data.length ~/ 5) != 0 &&
                                          value.toInt() != widget.data.length - 1) {
                                        return const SizedBox.shrink();
                                      }
                                    }
                                    
                                    final date = widget.data[value.toInt()].date;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('MMM d').format(date),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: widget.showLabels,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        '₹${value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: widget.showGrid,
                              drawVerticalLine: widget.showGrid,
                              horizontalInterval: (maxY! - minY!) / 5,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.3),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            minX: 0,
                            maxX: widget.data.length - 1.0,
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(widget.data.length, (index) {
                                  return FlSpot(index.toDouble(), widget.data[index].price);
                                }),
                                isCurved: true,
                                curveSmoothness: 0.3,
                                color: widget.lineColor,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: widget.showAreaFill
                                    ? BarAreaData(
                                        show: true,
                                        color: widget.lineColor.withOpacity(0.15),
                                      )
                                    : BarAreaData(show: false),
                              ),
                            ],
                          ),
                          // swapAnimationDuration: widget.animate 
                          //     ? const Duration(milliseconds: 650) 
                          //     : Duration.zero,
                          // swapAnimationCurve: Curves.easeInOutQuart,
                        ),
                      ),
                      if (widget.yAxisTitle != null)
                        Positioned(
                          left: 0,
                          top: widget.height / 2 - 50,
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              widget.yAxisTitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      if (widget.xAxisTitle != null)
                        Positioned(
                          bottom: 0,
                          right: widget.height / 2 - 50,
                          child: Text(
                            widget.xAxisTitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (widget.data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceStat(
                    'Min',
                    _getMinPrice(),
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                  _buildPriceStat(
                    'Max',
                    _getMaxPrice(),
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                  _buildPriceStat(
                    'Avg',
                    _getAvgPrice(),
                    Icons.stacked_line_chart,
                    Colors.blue,
                  ),
                  _buildPriceStat(
                    'Change',
                    '${_getPriceChange() >= 0 ? '+' : ''}${_getPriceChange().toStringAsFixed(1)}%',
                    _getPriceChange() >= 0 ? Icons.trending_up : Icons.trending_down,
                    _getPriceChange() >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _getMinPrice() {
    if (widget.data.isEmpty) return 0;
    return widget.data.map((point) => point.price).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    if (widget.data.isEmpty) return 0;
    return widget.data.map((point) => point.price).reduce((a, b) => a > b ? a : b);
  }

  double _getAvgPrice() {
    if (widget.data.isEmpty) return 0;
    final sum = widget.data.fold<double>(0, (sum, point) => sum + point.price);
    return sum / widget.data.length;
  }

  double _getPriceChange() {
    if (widget.data.length < 2) return 0;
    final firstPrice = widget.data.first.price;
    final lastPrice = widget.data.last.price;
    
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  Widget _buildPriceStat(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 14.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value is double ? '₹${value.toStringAsFixed(widget.decimalDigits ?? 0)}' : value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      items: items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
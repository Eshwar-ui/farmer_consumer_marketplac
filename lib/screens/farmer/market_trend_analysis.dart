import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';

class MarketTrendAnalysis extends StatefulWidget {
  @override
  _MarketTrendAnalysisState createState() => _MarketTrendAnalysisState();
}

class _MarketTrendAnalysisState extends State<MarketTrendAnalysis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedCrop = 'All';
  String _selectedTimeframe = '1 Month';

  // Mock data
  List<Map<String, dynamic>> _trendData = [];
  List<Map<String, dynamic>> _demandTrends = [];
  List<Map<String, dynamic>> _opportunityInsights = [];
  List<Map<String, dynamic>> _priceVolatility = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API delay
    Future.delayed(Duration(milliseconds: 800), () {
      // Mock top trends data
      _trendData = [
        {
          'crop': 'Tomatoes',
          'trend': 'up',
          'percentage': 15.0,
          'avgPrice': 45.0,
          'demand': 'high',
        },
        {
          'crop': 'Potatoes',
          'trend': 'down',
          'percentage': 5.0,
          'avgPrice': 25.0,
          'demand': 'stable',
        },
        {
          'crop': 'Onions',
          'trend': 'up',
          'percentage': 10.0,
          'avgPrice': 35.0,
          'demand': 'increasing',
        },
        {
          'crop': 'Rice',
          'trend': 'stable',
          'percentage': 0.5,
          'avgPrice': 80.0,
          'demand': 'stable',
        },
        {
          'crop': 'Wheat',
          'trend': 'down',
          'percentage': 3.0,
          'avgPrice': 30.0,
          'demand': 'decreasing',
        },
        {
          'crop': 'Apples',
          'trend': 'up',
          'percentage': 12.0,
          'avgPrice': 120.0,
          'demand': 'high',
        },
        {
          'crop': 'Oranges',
          'trend': 'up',
          'percentage': 8.0,
          'avgPrice': 90.0,
          'demand': 'increasing',
        },
      ];

      // Mock demand trends data
      _demandTrends = [
        {
          'category': 'Organic Products',
          'trend': 'up',
          'percentage': 18.0,
          'note': 'Growing health consciousness is driving demand',
        },
        {
          'category': 'Exotic Vegetables',
          'trend': 'up',
          'percentage': 25.0,
          'note': 'Urban consumers seeking variety',
        },
        {
          'category': 'Fruits',
          'trend': 'up',
          'percentage': 12.0,
          'note': 'Seasonal demand with premium pricing',
        },
        {
          'category': 'Dairy Products',
          'trend': 'stable',
          'percentage': 2.0,
          'note': 'Consistent demand throughout the year',
        },
        {
          'category': 'Grains',
          'trend': 'down',
          'percentage': 3.0,
          'note': 'Oversupply in the market',
        },
      ];

      // Mock opportunity insights
      _opportunityInsights = [
        {
          'title': 'Organic Vegetables',
          'description':
              'Growing demand with 25% higher profit margins than conventional farming.',
          'impact': 'high',
          'timeframe': 'Long-term',
        },
        {
          'title': 'Hydroponics',
          'description':
              'Urban farming technology enabling year-round production with higher yields.',
          'impact': 'medium',
          'timeframe': 'Medium-term',
        },
        {
          'title': 'Direct-to-Consumer Sales',
          'description':
              'Eliminate middlemen to increase profits by up to 40%.',
          'impact': 'high',
          'timeframe': 'Immediate',
        },
        {
          'title': 'Value-Added Products',
          'description':
              'Processing raw produce into pickles, jams, etc. can increase revenue by 60%.',
          'impact': 'medium',
          'timeframe': 'Medium-term',
        },
        {
          'title': 'Export Markets',
          'description':
              'International markets offering premium prices for quality produce.',
          'impact': 'high',
          'timeframe': 'Long-term',
        },
      ];

      // Mock price volatility data
      _priceVolatility = [
        {
          'crop': 'Tomatoes',
          'volatility': 35.0,
          'stability': 'low',
          'seasonality': 'high',
        },
        {
          'crop': 'Potatoes',
          'volatility': 15.0,
          'stability': 'high',
          'seasonality': 'low',
        },
        {
          'crop': 'Onions',
          'volatility': 40.0,
          'stability': 'low',
          'seasonality': 'high',
        },
        {
          'crop': 'Rice',
          'volatility': 8.0,
          'stability': 'very high',
          'seasonality': 'low',
        },
        {
          'crop': 'Wheat',
          'volatility': 12.0,
          'stability': 'high',
          'seasonality': 'moderate',
        },
        {
          'crop': 'Apples',
          'volatility': 25.0,
          'stability': 'moderate',
          'seasonality': 'high',
        },
      ];

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Crop',
                    value: _selectedCrop,
                    items: ['All', 'Vegetables', 'Fruits', 'Grains', 'Dairy'],
                    onChanged: (value) {
                      setState(() {
                        _selectedCrop = value!;
                      });
                      _loadData();
                    },
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: _buildDropdown(
                    label: 'Timeframe',
                    value: _selectedTimeframe,
                    items: ['1 Month', '3 Months', '6 Months', '1 Year'],
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeframe = value!;
                      });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(text: 'Top Trends'),
                Tab(text: 'Demand'),
                Tab(text: 'Opportunities'),
                Tab(text: 'Volatility'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        // Top trends tab
                        _buildTopTrendsTab(),

                        // Demand trends tab
                        _buildDemandTrendsTab(),

                        // Opportunity insights tab
                        _buildOpportunityInsightsTab(),

                        // Price volatility tab
                        // _buildPriceVolatilityTab(),
                      ],
                    ),
          ),
        ],
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
        Text(label, style: TextStyle(fontSize: 12.0, color: Colors.grey[600])),
        SizedBox(height: 4.0),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items:
                items.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item));
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTopTrendsTab() {
    final topTrendsData =
        _trendData.where((item) {
          if (_selectedCrop == 'All') return true;

          if (_selectedCrop == 'Vegetables') {
            return ['Tomatoes', 'Potatoes', 'Onions'].contains(item['crop']);
          } else if (_selectedCrop == 'Fruits') {
            return ['Apples', 'Oranges'].contains(item['crop']);
          } else if (_selectedCrop == 'Grains') {
            return ['Rice', 'Wheat'].contains(item['crop']);
          } else if (_selectedCrop == 'Dairy') {
            return false; // No dairy items in our sample data
          }

          return false;
        }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market summary card
          Card(
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
                    'Market Summary',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'The agricultural market is showing an overall upward trend with a 8.2% increase in prices compared to last $_selectedTimeframe. Organic products continue to fetch premium prices.',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    height: 200.0,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 15,
                        minY: -5,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            // tooltipBgColor: Colors.white.withOpacity(0.8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final categories = [
                                'Vegetables',
                                'Fruits',
                                'Grains',
                                'Dairy',
                              ];
                              final colors = [
                                Colors.green,
                                Colors.blue,
                                Colors.red,
                                Colors.amber,
                              ];
                              return BarTooltipItem(
                                '${categories[group.x.toInt()]}\n',
                                TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${rod.toY.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: colors[group.x.toInt()],
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
                                final categories = [
                                  'Vegetables',
                                  'Fruits',
                                  'Grains',
                                  'Dairy',
                                ];
                                if (value >= categories.length || value < 0) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    categories[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
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
                                    '${value.toInt()}%',
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
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
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
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: 12.5,
                                color: Colors.green,
                                width: 25,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: 8.7,
                                color: Colors.blue,
                                width: 25,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: -3.2,
                                color: Colors.red,
                                width: 25,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: 2.1,
                                color: Colors.amber,
                                width: 25,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      swapAnimationDuration: Duration(milliseconds: 400),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.0),

          // Top trends list
          Text(
            'Price Trends by Crop',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          ...topTrendsData.map((item) {
            final isUp = item['trend'] == 'up';
            final isStable = item['trend'] == 'stable';
            final color =
                isUp ? Colors.green : (isStable ? Colors.blue : Colors.red);
            final icon =
                isUp
                    ? Icons.trending_up
                    : (isStable ? Icons.trending_flat : Icons.trending_down);

            return Card(
              margin: EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                title: Text(
                  item['crop'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Avg. Price: ₹${item['avgPrice']} | Demand: ${item['demand'].toString().toUpperCase()}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color),
                    SizedBox(width: 4.0),
                    Text(
                      '${isStable ? '' : (isUp ? '+' : '-')}${item['percentage']}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Show detailed analysis for the crop
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDemandTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demand analysis card
          Card(
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
                    'Demand Analysis',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Consumer preferences are shifting towards organic and locally-grown produce, with an emphasis on quality and sustainability. Urban markets show higher demand for premium products.',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    height: 200.0,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 35,
                            title: '35%',
                            color: Colors.green,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 42,
                            title: '42%',
                            color: Colors.blue,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 18,
                            title: '18%',
                            color: Colors.purple,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 5,
                            title: '5%',
                            color: Colors.grey,
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: 270,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPieLegendItem('Organic', Colors.green),
                      _buildPieLegendItem('Conventional', Colors.blue),
                      _buildPieLegendItem('Premium', Colors.purple),
                      _buildPieLegendItem('Other', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.0),

          // Demand trends list
          Text(
            'Current Demand Trends',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          ..._demandTrends.map((item) {
            final isUp = item['trend'] == 'up';
            final isStable = item['trend'] == 'stable';
            final color =
                isUp ? Colors.green : (isStable ? Colors.blue : Colors.red);
            final icon =
                isUp
                    ? Icons.trending_up
                    : (isStable ? Icons.trending_flat : Icons.trending_down);

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['category'],
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 14.0),
                              SizedBox(width: 4.0),
                              Text(
                                '${isStable ? '' : (isUp ? '+' : '-')}${item['percentage']}%',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      item['note'],
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          SizedBox(height: 16.0),

          // Consumer preferences card
          Card(
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
                    'Consumer Preferences',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  _buildPreferenceItem('Organic Products', 0.72),
                  SizedBox(height: 12.0),
                  _buildPreferenceItem('Locally Sourced', 0.68),
                  SizedBox(height: 12.0),
                  _buildPreferenceItem('Pesticide-Free', 0.65),
                  SizedBox(height: 12.0),
                  _buildPreferenceItem('Fresh Produce', 0.85),
                  SizedBox(height: 12.0),
                  _buildPreferenceItem('Value for Money', 0.78),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPreferenceItem(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${(value * 100).toInt()}%')],
        ),
        SizedBox(height: 4.0),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[200],
          minHeight: 8.0,
          borderRadius: BorderRadius.circular(4.0),
        ),
      ],
    );
  }

  Widget _buildOpportunityInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opportunity overview card
          Card(
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
                    'Opportunity Overview',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'The agricultural market presents several opportunities for growth and increased profitability. Analysis of market trends and consumer behavior reveals the following key opportunities:',
                    style: TextStyle(fontSize: 14.0),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.0),

          // Opportunity insights list
          Text(
            'Market Opportunities',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          ..._opportunityInsights.map((item) {
            Color impactColor;
            if (item['impact'] == 'high') {
              impactColor = Colors.green;
            } else if (item['impact'] == 'medium') {
              impactColor = Colors.amber;
            } else {
              impactColor = Colors.blue;
            }

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: impactColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            '${item['impact'].toString().toUpperCase()} Impact',
                            style: TextStyle(
                              color: impactColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.0),
                    Text(item['description'], style: TextStyle(fontSize: 14.0)),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.0,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          'Timeframe: ${item['timeframe']}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

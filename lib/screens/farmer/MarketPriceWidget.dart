// lib/screens/market_price_screen.dart

import 'package:farmer_consumer_marketplace/services/market_data_service.dart';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({Key? key}) : super(key: key);

  @override
  _MarketPriceScreenState createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final AgmarknetService _agmarknetService = AgmarknetService();

  List<MarketPrice> _prices = [];
  bool _isLoading = false;
  String? _error;

  // Filter options
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _commodities = [];

  // Selected filters
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCommodity;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load filter options
      final statesData = await _agmarknetService.getStates();
      final commoditiesData = await _agmarknetService.getCommodities();

      setState(() {
        _states = statesData;
        _commodities = commoditiesData;

        // Set default selections
        if (_states.isNotEmpty) {
          _selectedState = 'Maharashtra'; // Default to Maharashtra if available
        }

        if (_commodities.isNotEmpty) {
          _selectedCommodity = 'Tomato'; // Default to Tomato if available
        }
      });

      // Load districts for the selected state
      if (_selectedState != null) {
        await _loadDistricts();
      }

      // Load initial data with default filters
      await _fetchMarketPrices();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMarketPrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? formattedDate;
      if (_selectedDate != null) {
        formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      }

      // Return early if neither state nor commodity is selected
      if (_selectedState == null && _selectedCommodity == null) {
        setState(() {
          _error = "Please select at least a state or commodity";
          _isLoading = false;
        });
        return;
      }

      final data = await _agmarknetService.getMarketPrices(
        state: _selectedState,
        district: _selectedDistrict,
        commodity: _selectedCommodity,
        arrivalDate: formattedDate,
        limit: 10, // Always limit to 10 as required
      );

      if (data['records'] != null) {
        if (data['records'].isEmpty) {
          setState(() {
            _error =
                "No records found for this selection. Try changing filters.";
            _prices = [];
          });
        } else {
          setState(() {
            _prices = MarketPrice.fromJsonList(data['records']);
            _error = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}\nTry a different state or commodity.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDistricts() async {
    if (_selectedState == null) {
      setState(() {
        _districts = [];
        _selectedDistrict = null;
      });
      return;
    }

    try {
      final districtsData = await _agmarknetService.getDistricts(
        _selectedState!,
      );
      setState(() {
        _districts = districtsData;
        _selectedDistrict = null;
      });
    } catch (e) {
      // Handle error
    }
  }

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Prices'),

      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                    : _error != null
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _loadInitialData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh with Default Values'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : _buildPricesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Market Prices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Add a refresh button
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.green[700]),
                onPressed: _loadInitialData,
                tooltip: 'Refresh data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // State field - Always visible and important
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'State *',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select a state',
            ),
            value: _selectedState,
            isExpanded: true,
            items: [
              ..._states.map(
                (state) =>
                    DropdownMenuItem<String>(value: state, child: Text(state)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedState = value;
              });
              _loadDistricts();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: _selectedDistrict,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Districts'),
                    ),
                    ..._districts.map(
                      (district) => DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Commodity *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: 'Select a commodity',
                  ),
                  value: _selectedCommodity,
                  isExpanded: true,
                  items:
                      _commodities
                          .map(
                            (commodity) => DropdownMenuItem<String>(
                              value: commodity,
                              child: Text(commodity),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCommodity = value;
                    });
                    // Fetch data immediately when commodity changes
                    if (_selectedState != null && _selectedCommodity != null) {
                      _fetchMarketPrices();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchMarketPrices,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList() {
    if (_prices.isEmpty) {
      return const Center(child: Text('No market prices found'));
    }

    return ListView.builder(
      itemCount: _prices.length,
      itemBuilder: (context, index) {
        final price = _prices[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${price.commodity} (${price.variety})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      price.arrivalDate,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('State', price.state)),
                    Expanded(child: _buildInfoItem('District', price.district)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildInfoItem('Market', price.market)),
                    Expanded(child: _buildInfoItem('Grade', price.grade)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Price Range (₹)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPriceItem('Min', price.minPrice)),
                    Expanded(
                      child: _buildPriceItem(
                        'Modal',
                        price.modalPrice,
                        isHighlighted: true,
                      ),
                    ),
                    Expanded(child: _buildPriceItem('Max', price.maxPrice)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildPriceItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlighted ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: isHighlighted ? Border.all(color: Colors.green.shade700) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          Text(
            '₹$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }
}

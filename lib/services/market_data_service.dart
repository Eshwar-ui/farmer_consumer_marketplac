// lib/services/agmarknet_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AgmarknetService {
  static const String baseUrl = 'https://api.data.gov.in/resource/';
  static const String resourceId = '35985678-0d79-46b4-9ed6-6f13308a1d24';
  static const String apiKey = '579b464db66ec23bdd000001c233f96a834e4df0593c828ff0826d82';

  Future<Map<String, dynamic>> getMarketPrices({
    String? state,
    String? district,
    String? commodity,
    String? arrivalDate,
    int offset = 0,
    int limit = 10,
    String format = 'json',
  }) async {
    // Always limit to 10 results as per requirement
    limit = 10;
    Map<String, String> queryParams = {
      'api-key': apiKey,
      'format': format,
      'offset': offset.toString(),
      'limit': limit.toString(),
    };

    // Add optional filters
    if (state != null && state.isNotEmpty) {
      queryParams['filters[State.keyword]'] = state;
    }

    if (district != null && district.isNotEmpty) {
      queryParams['filters[District.keyword]'] = district;
    }

    if (commodity != null && commodity.isNotEmpty) {
      queryParams['filters[Commodity.keyword]'] = commodity;
    }

    if (arrivalDate != null && arrivalDate.isNotEmpty) {
      queryParams['filters[Arrival_Date]'] = arrivalDate;
    }

    final uri = Uri.parse('$baseUrl$resourceId').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load market data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching market data: $e');
    }
  }

  // Get list of states
  Future<List<String>> getStates() async {
    final data = await getMarketPrices(limit: 100);
    
    if (data['records'] != null) {
      final Set<String> states = {};
      for (var item in data['records']) {
        states.add(item['State']);
      }
      return states.toList()..sort();
    }
    
    return [];
  }

  // Get districts for a state
  Future<List<String>> getDistricts(String state) async {
    final data = await getMarketPrices(state: state, limit: 100);
    
    if (data['records'] != null) {
      final Set<String> districts = {};
      for (var item in data['records']) {
        districts.add(item['District']);
      }
      return districts.toList()..sort();
    }
    
    return [];
  }

  // Get commodities - using a direct API call with a larger limit to get more variety
  Future<List<String>> getCommodities() async {
    try {
      // Make a dedicated API call to get a variety of commodities
      Map<String, String> queryParams = {
        'api-key': apiKey,
        'format': 'json',
        'limit': '50',
      };
      
      final uri = Uri.parse('$baseUrl$resourceId').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['records'] != null) {
          final Set<String> commodities = {};
          for (var item in data['records']) {
            commodities.add(item['Commodity']);
          }
          
          // Add common commodities in case they're not in the first 50 results
          commodities.addAll([
            'Tomato',
            'Potato',
            'Onion',
            'Rice',
            'Wheat',
            'Maize',
            'Coriander',
            'Chilli',
            'Soyabean',
            'Cotton',
          ]);
          
          return commodities.toList()..sort();
        }
      }
      return [];
    } catch (e) {
      // Fallback to common commodities if API fails
      return [
        'Tomato',
        'Potato',
        'Onion',
        'Rice',
        'Wheat',
        'Maize',
        'Coriander',
        'Chilli',
        'Soyabean',
        'Cotton',
      ]..sort();
    }
  }
}

// Model class for market data
class MarketPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final String minPrice;
  final String maxPrice;
  final String modalPrice;
  final String commodityCode;

  MarketPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.commodityCode,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      state: json['State'] ?? '',
      district: json['District'] ?? '',
      market: json['Market'] ?? '',
      commodity: json['Commodity'] ?? '',
      variety: json['Variety'] ?? '',
      grade: json['Grade'] ?? '',
      arrivalDate: json['Arrival_Date'] ?? '',
      minPrice: json['Min_Price'] ?? '',
      maxPrice: json['Max_Price'] ?? '',
      modalPrice: json['Modal_Price'] ?? '',
      commodityCode: json['Commodity_Code'] ?? '',
    );
  }

  static List<MarketPrice> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => MarketPrice.fromJson(json)).toList();
  }
}
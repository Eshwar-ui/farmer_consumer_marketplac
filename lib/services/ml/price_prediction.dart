import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;

class PricePredictionModel {
  late Interpreter _interpreter;
  late Map<String, int> _cropIndices;
  late Map<String, int> _locationIndices;
  bool _isModelLoaded = false;

  // Singleton pattern
  static final PricePredictionModel _instance = PricePredictionModel._internal();
  factory PricePredictionModel() => _instance;
  PricePredictionModel._internal();

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/ml/price_prediction_model.tflite');
      
      // Load crop indices
      final String cropData = await rootBundle.loadString('assets/ml/crop_indices.json');
      _cropIndices = Map<String, int>.from(jsonDecode(cropData));
      
      // Load location indices
      final String locationData = await rootBundle.loadString('assets/ml/location_indices.json');
      _locationIndices = Map<String, int>.from(jsonDecode(locationData));
      
      _isModelLoaded = true;
      print('Price prediction model loaded successfully');
    } catch (e) {
      print('Error loading price prediction model: $e');
      throw Exception('Failed to load price prediction model: $e');
    }
  }

  /// Predicts the price for a specific crop based on various factors
  /// 
  /// Parameters:
  /// - cropName: Name of the crop
  /// - location: Location/region
  /// - month: Month (1-12)
  /// - supplyLevel: Supply level (0.0-1.0)
  /// - demandLevel: Demand level (0.0-1.0)
  /// - rainfall: Rainfall in mm
  Future<PricePrediction> predictPrice({
    required String cropName,
    required String location,
    required int month,
    required double supplyLevel,
    required double demandLevel,
    required double rainfall,
  }) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    // Check if crop and location are in our model's vocabulary
    if (!_cropIndices.containsKey(cropName) || !_locationIndices.containsKey(location)) {
      throw Exception('Crop or location not supported by the model');
    }

    // One-hot encode crop and location
    final cropIndex = _cropIndices[cropName] ?? 0;
    final locationIndex = _locationIndices[location] ?? 0;

    // Input data needs to be properly formatted as expected by the model
    // This is a simplified example; real models may have different input formats
    final input = [
      [
        month / 12.0,  // Normalize month
        cropIndex.toDouble(),
        locationIndex.toDouble(),
        supplyLevel,
        demandLevel,
        rainfall / 500.0,  // Normalize rainfall
      ]
    ];

    // Output tensor shape should match model output
    // Assuming the model outputs minimum, average, and maximum price
    final output = List<List<double>>.filled(1, List<double>.filled(3, 0.0));

    // Run inference
    _interpreter.run(input, output);

    // Process results - denormalize if needed
    final minPrice = output[0][0] * 100;  // Example scaling factor
    final avgPrice = output[0][1] * 100;
    final maxPrice = output[0][2] * 100;

    // Get historical data for comparison
    final historicalData = await _fetchHistoricalPriceData(cropName, location);

    return PricePrediction(
      crop: cropName,
      location: location,
      predictedMinPrice: minPrice,
      predictedAvgPrice: avgPrice,
      predictedMaxPrice: maxPrice,
      historicalMinPrice: historicalData['min_price'] ?? 0.0,
      historicalAvgPrice: historicalData['avg_price'] ?? 0.0,
      historicalMaxPrice: historicalData['max_price'] ?? 0.0,
      factors: {
        'Supply Level': supplyLevel,
        'Demand Level': demandLevel,
        'Rainfall': rainfall,
        'Season': _getSeasonFromMonth(month),
      },
    );
  }

  // Helper to fetch historical price data for comparison
  Future<Map<String, double>> _fetchHistoricalPriceData(String crop, String location) async {
    try {
      // Replace with your actual market data API endpoint
      final response = await http.get(
        Uri.parse('https://api.marketdata.gov/prices?crop=$crop&location=$location&key=YOUR_API_KEY')
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'min_price': data['min_price'] ?? 0.0,
          'avg_price': data['avg_price'] ?? 0.0,
          'max_price': data['max_price'] ?? 0.0,
        };
      } else {
        throw Exception('Failed to load historical price data');
      }
    } catch (e) {
      print('Error fetching historical price data: $e');
      // Return default values if API fails
      return {
        'min_price': 0.0,
        'avg_price': 0.0,
        'max_price': 0.0,
      };
    }
  }

  String _getSeasonFromMonth(int month) {
    // Northern hemisphere seasons (customize based on your region)
    if (month >= 3 && month <= 5) {
      return 'Spring';
    } else if (month >= 6 && month <= 8) {
      return 'Summer';
    } else if (month >= 9 && month <= 11) {
      return 'Autumn';
    } else {
      return 'Winter';
    }
  }

  /// Analyze price trends for a specific crop
  Future<PriceTrendAnalysis> analyzePriceTrends(String crop, String location) async {
    try {
      // Get historical price data for the last 12 months
      final monthlySeries = await _fetchMonthlyPriceData(crop, location);
      
      // Calculate growth rates and volatility
      final growthRate = _calculateGrowthRate(monthlySeries);
      final volatility = _calculateVolatility(monthlySeries);
      
      // Determine trend direction
      String trendDirection;
      if (growthRate > 5) {
        trendDirection = 'Strongly Upward';
      } else if (growthRate > 0) {
        trendDirection = 'Slightly Upward';
      } else if (growthRate > -5) {
        trendDirection = 'Slightly Downward';
      } else {
        trendDirection = 'Strongly Downward';
      }
      
      // Generate recommendation based on trend analysis
      String recommendation;
      if (trendDirection.contains('Upward') && volatility < 10) {
        recommendation = 'Consider selling as prices are rising with low volatility';
      } else if (trendDirection.contains('Upward') && volatility >= 10) {
        recommendation = 'Prices are rising but volatile - monitor market closely';
      } else if (trendDirection.contains('Downward') && volatility < 10) {
        recommendation = 'Consider holding stock as prices are steadily declining';
      } else {
        recommendation = 'Market is unstable - consider diversifying products';
      }
      
      return PriceTrendAnalysis(
        crop: crop,
        location: location,
        monthlyPrices: monthlySeries,
        growthRate: growthRate,
        volatility: volatility,
        trendDirection: trendDirection,
        recommendation: recommendation,
      );
    } catch (e) {
      print('Error analyzing price trends: $e');
      throw Exception('Failed to analyze price trends: $e');
    }
  }

  // Helper to fetch monthly price data
  Future<List<MonthlyPrice>> _fetchMonthlyPriceData(String crop, String location) async {
    try {
      // Replace with your actual market data API endpoint
      final response = await http.get(
        Uri.parse('https://api.marketdata.gov/monthly_prices?crop=$crop&location=$location&key=YOUR_API_KEY')
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => MonthlyPrice(
          month: item['month'],
          year: item['year'],
          price: item['price'].toDouble(),
        )).toList();
      } else {
        throw Exception('Failed to load monthly price data');
      }
    } catch (e) {
      print('Error fetching monthly price data: $e');
      // Return dummy data if API fails
      return List.generate(12, (index) => MonthlyPrice(
        month: index + 1,
        year: DateTime.now().year,
        price: 50.0 + (index * 2.5), // Dummy increasing price trend
      ));
    }
  }

  // Calculate annualized growth rate from monthly price series
  double _calculateGrowthRate(List<MonthlyPrice> monthlySeries) {
    if (monthlySeries.length < 2) return 0.0;
    
    final firstPrice = monthlySeries.first.price;
    final lastPrice = monthlySeries.last.price;
    
    if (firstPrice <= 0) return 0.0;
    
    // Calculate percentage change
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  // Calculate price volatility (standard deviation)
  double _calculateVolatility(List<MonthlyPrice> monthlySeries) {
    if (monthlySeries.length < 2) return 0.0;
    
    // Calculate mean price
    final meanPrice = monthlySeries.fold<double>(
      0, (sum, item) => sum + item.price) / monthlySeries.length;
    
    // Calculate variance
    final variance = monthlySeries.fold<double>(
      0, (sum, item) => sum + pow(item.price - meanPrice, 2)) / monthlySeries.length;
    
    // Return standard deviation as percentage of mean
    return (sqrt(variance) / meanPrice) * 100;
  }

  double pow(double x, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= x;
    }
    return result;
  }

  double sqrt(double x) {
    if (x <= 0) return 0;
    double result = x;
    for (int i = 0; i < 10; i++) {
      result = 0.5 * (result + x / result);
    }
    return result;
  }

  void dispose() {
    if (_isModelLoaded) {
      _interpreter.close();
    }
  }
}

class PricePrediction {
  final String crop;
  final String location;
  final double predictedMinPrice;
  final double predictedAvgPrice;
  final double predictedMaxPrice;
  final double historicalMinPrice;
  final double historicalAvgPrice;
  final double historicalMaxPrice;
  final Map<String, dynamic> factors;

  PricePrediction({
    required this.crop,
    required this.location,
    required this.predictedMinPrice,
    required this.predictedAvgPrice,
    required this.predictedMaxPrice,
    required this.historicalMinPrice,
    required this.historicalAvgPrice,
    required this.historicalMaxPrice,
    required this.factors,
  });
}

class PriceTrendAnalysis {
  final String crop;
  final String location;
  final List<MonthlyPrice> monthlyPrices;
  final double growthRate;
  final double volatility;
  final String trendDirection;
  final String recommendation;

  PriceTrendAnalysis({
    required this.crop,
    required this.location,
    required this.monthlyPrices,
    required this.growthRate,
    required this.volatility,
    required this.trendDirection,
    required this.recommendation,
  });
}

class MonthlyPrice {
  final int month;
  final int year;
  final double price;

  MonthlyPrice({
    required this.month,
    required this.year,
    required this.price,
  });
}
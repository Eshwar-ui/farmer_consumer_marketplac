import 'dart:convert';
import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  final String apiKey = '356df7b6f5e620cad2cb953a0d0a21fe';
  final String baseUrl = 'http://api.weatherstack.com';

  Future<Map<String, dynamic>> getCurrentWeather(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/current?access_key=$apiKey&query=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the API returned an error
        if (data.containsKey('error')) {
          throw Exception(data['error']['info']);
        }

        return data;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  Future<Map<String, dynamic>> getForecast(String query, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/forecast?access_key=$apiKey&query=$query&forecast_days=$days',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if the API returned an error
        if (data.containsKey('error')) {
          throw Exception(data['error']['info']);
        }

        return data;
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }
}

class SoilService {
  final String baseUrl = 'https://api.openepi.io/soil';

  Future<Map<String, dynamic>> getSoilType(
    double lat,
    double lon, {
    int topK = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/type?lat=$lat&lon=$lon&top_k=$topK'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load soil type data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching soil type data: $e');
    }
  }

  Future<Map<String, dynamic>> getSoilProperties(
    double lat,
    double lon, {
    List<String> depths = const ['0-30cm'],
    List<String> properties = const [
      'phh2o',
      'nitrogen',
      'clay',
      'sand',
      'silt',
    ],
    List<String> values = const ['mean'],
  }) async {
    try {
      // Build query parameters for multiple values
      String depthParams = depths.map((d) => 'depths=$d').join('&');
      String propertyParams = properties.map((p) => 'properties=$p').join('&');
      String valueParams = values.map((v) => 'values=$v').join('&');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/property?lat=$lat&lon=$lon&$depthParams&$propertyParams&$valueParams',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load soil property data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching soil property data: $e');
    }
  }
}

// Map for default soil parameters by region
class IndianSoilParameters {
  static final Map<String, Map<String, dynamic>> soilByRegion = {
    'Default': {
      'type': 'Medium Loam',
      'properties': {
        'nitrogen': 280, // kg/ha
        'phosphorus': 25, // kg/ha
        'potassium': 200, // kg/ha
        'ph': 6.8,
        'clay': 0.25,
        'silt': 0.40,
        'sand': 0.35,
      },
    },
    'North India': {
      'type': 'Alluvial Soil',
      'properties': {
        'nitrogen': 280, // kg/ha
        'phosphorus': 22, // kg/ha
        'potassium': 250, // kg/ha
        'ph': 7.5,
        'clay': 0.20,
        'silt': 0.50,
        'sand': 0.30,
      },
    },
    'South India': {
      'type': 'Red Soil',
      'properties': {
        'nitrogen': 220, // kg/ha
        'phosphorus': 18, // kg/ha
        'potassium': 180, // kg/ha
        'ph': 6.2,
        'clay': 0.30,
        'silt': 0.25,
        'sand': 0.45,
      },
    },
    'East India': {
      'type': 'Laterite Soil',
      'properties': {
        'nitrogen': 240, // kg/ha
        'phosphorus': 15, // kg/ha
        'potassium': 170, // kg/ha
        'ph': 5.8,
        'clay': 0.35,
        'silt': 0.30,
        'sand': 0.35,
      },
    },
    'West India': {
      'type': 'Black Soil (Regur)',
      'properties': {
        'nitrogen': 260, // kg/ha
        'phosphorus': 28, // kg/ha
        'potassium': 290, // kg/ha
        'ph': 7.8,
        'clay': 0.45,
        'silt': 0.30,
        'sand': 0.25,
      },
    },
    'Central India': {
      'type': 'Black Cotton Soil',
      'properties': {
        'nitrogen': 250, // kg/ha
        'phosphorus': 30, // kg/ha
        'potassium': 300, // kg/ha
        'ph': 7.9,
        'clay': 0.50,
        'silt': 0.30,
        'sand': 0.20,
      },
    },
  };

  // Average rainfall by region (mm/year)
  static final Map<String, double> rainfallByRegion = {
    'Default': 1100.0,
    'North India': 915.0,
    'South India': 1290.0,
    'East India': 1750.0,
    'West India': 880.0,
    'Central India': 1020.0,
  };

  static Map<String, dynamic> getSoilParametersForRegion(String region) {
    return soilByRegion[region] ?? soilByRegion['Default']!;
  }

  static double getRainfallForRegion(String region) {
    return rainfallByRegion[region] ?? rainfallByRegion['Default']!;
  }
}

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final nController = TextEditingController();
  final pController = TextEditingController();
  final kController = TextEditingController();
  final tempController = TextEditingController();
  final humidityController = TextEditingController();
  final phController = TextEditingController();
  final rainfallController = TextEditingController();
  final locationController = TextEditingController();

  // Selected region
  String _selectedRegion = 'Default';

  // Prediction results
  String? recommendedCrop;
  double? confidence;
  Map<String, double>? allScores;
  bool isLoading = false;
  bool isLoadingWeather = false;
  bool isLoadingSoil = false;

  // Weather and soil data
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? soilData;
  Map<String, dynamic>? soilTypeData;
  String? locationName;
  Position? currentPosition;
  String? soilType;
  Map<String, double>? soilProperties;

  // Model
  Interpreter? _interpreter;
  Map<String, dynamic>? _metadata;

  // Services
  final WeatherService _weatherService = WeatherService();
  final SoilService _soilService = SoilService();

  // Animation controller for recommended crop
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _getCurrentLocation();
    _populateDefaultSoilParameters();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    nController.dispose();
    pController.dispose();
    kController.dispose();
    tempController.dispose();
    humidityController.dispose();
    phController.dispose();
    rainfallController.dispose();
    locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _populateDefaultSoilParameters() {
    final soilParams = IndianSoilParameters.getSoilParametersForRegion(
      _selectedRegion,
    );
    final properties = soilParams['properties'] as Map<String, dynamic>;

    nController.text = properties['nitrogen'].toString();
    pController.text = properties['phosphorus'].toString();
    kController.text = properties['potassium'].toString();
    phController.text = properties['ph'].toString();
    rainfallController.text =
        IndianSoilParameters.getRainfallForRegion(_selectedRegion).toString();

    soilType = soilParams['type'];
    soilProperties = {
      'clay': properties['clay'],
      'silt': properties['silt'],
      'sand': properties['sand'],
      'ph': properties['ph'],
      'nitrogen':
          properties['nitrogen'] / 1000, // Convert to percentage for display
    };
  }

  Future<void> _loadModel() async {
    try {
      // Use the float model instead of int8 model to avoid type mismatches
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/crop_recommendation_model_float.tflite', // Use float model
        options: interpreterOptions,
      );

      // Load metadata
      final metadataString = await rootBundle.loadString(
        'assets/crop_model_metadata.json',
      );
      _metadata = jsonDecode(metadataString);

      print(
        'Model loaded successfully: Interpreter: ${_interpreter != null}, Metadata: ${_metadata != null}',
      );
    } catch (e) {
      print('Error loading model: $e');
      // Show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load crop model: $e')),
        );
      }
    }
  }

  List<double> _preprocess(List<double> input) {
    // The metadata contains min values and ranges for normalization
    final inputMean =
        _metadata!['input_mean'] is List
            ? (_metadata!['input_mean'] as List)
                .map((v) => v is num ? v.toDouble() : 0.0)
                .toList()
            : List<double>.filled(input.length, 0.0);

    final inputStd =
        _metadata!['input_std'] is List
            ? (_metadata!['input_std'] as List)
                .map((v) => v is num ? v.toDouble() : 1.0)
                .toList()
            : List<double>.filled(input.length, 1.0);

    // Ensure lists are the correct length
    while (inputMean.length < input.length) inputMean.add(0.0);
    while (inputStd.length < input.length) inputStd.add(1.0);

    // Apply the same normalization as in the Python code
    // normalized_input = (input_data - self.input_mean) / self.input_std
    List<double> normalized = [];
    for (int i = 0; i < input.length; i++) {
      normalized.add(
        (input[i] - inputMean[i]) / (inputStd[i] != 0 ? inputStd[i] : 1.0),
      );
    }

    return normalized;
  }

  Future<void> _predictCrop() async {
    if (_formKey.currentState?.validate() != true ||
        _interpreter == null ||
        _metadata == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get values from form
      final n = double.parse(nController.text);
      final p = double.parse(pController.text);
      final k = double.parse(kController.text);
      final temp = double.parse(tempController.text);
      final humidity = double.parse(humidityController.text);
      final ph = double.parse(phController.text);
      final rainfall = double.parse(rainfallController.text);

      // Preprocess input
      final input = [n, p, k, temp, humidity, ph, rainfall];
      print('Raw input: $input');

      final processedInput = _preprocess(input);
      print('Processed input: $processedInput');

      // Prepare output tensor with the right shape
      final numClasses = _metadata!['crop_dict'].length;
      final output = List<List<double>>.filled(
        1,
        List<double>.filled(numClasses, 0.0),
      );

      // Run inference
      _interpreter!.run([processedInput], output);
      print('Model output: ${output[0]}');

      // Process results
      final predictions = output[0];
      int maxIndex = 0;
      double maxValue = predictions[0];

      for (int i = 1; i < predictions.length; i++) {
        if (predictions[i] > maxValue) {
          maxValue = predictions[i];
          maxIndex = i;
        }
      }

      // Convert back to crop name (adding 1 because indices are 1-based in metadata)
      final cropIndex = (maxIndex + 1).toString();
      final cropDictReverse = Map<String, String>.from(
        _metadata!['crop_dict_reverse'],
      );

      setState(() {
        recommendedCrop = cropDictReverse[cropIndex] ?? 'Unknown';
        confidence = maxValue;

        // Get all scores
        allScores = {};
        for (int i = 0; i < predictions.length; i++) {
          final cropKey = (i + 1).toString();
          if (cropDictReverse.containsKey(cropKey)) {
            allScores![cropDictReverse[cropKey]!] = predictions[i];
          }
        }

        isLoading = false;
      });

      // Start animation for results
      if (mounted) {
        _animationController.reset();
        _animationController.forward();
      }

      print(
        'Prediction complete. Recommended crop: $recommendedCrop, Confidence: $confidence',
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error during prediction: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Location permission and handling
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

    setState(() {
      isLoadingWeather = true;
      isLoadingSoil = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentPosition = position;
      });

      // Get address from location
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String cityName = place.locality ?? '';
        String countryName = place.country ?? '';

        setState(() {
          locationName =
              cityName.isNotEmpty ? "$cityName, $countryName" : countryName;
          locationController.text = locationName ?? '';
        });

        // Get weather data for the location
        if (locationName != null && locationName!.isNotEmpty) {
          await _fetchWeatherData(locationName!);
        }

        // Get soil data for the location
        await _fetchSoilData(position.latitude, position.longitude);
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() {
        isLoadingWeather = false;
        isLoadingSoil = false;
      });
    }
  }

  Future<void> _fetchWeatherData(String location) async {
    setState(() {
      isLoadingWeather = true;
    });

    try {
      final data = await _weatherService.getCurrentWeather(location);

      setState(() {
        weatherData = data;

        // Update the form fields with weather data
        if (data.containsKey('current')) {
          final current = data['current'];
          tempController.text = current['temperature']?.toString() ?? '';
          humidityController.text = current['humidity']?.toString() ?? '';

          // Estimated rainfall from precipitation (very rough approximation)
          // Adjust this logic if your API provides better rainfall data
          if (current.containsKey('precip')) {
            // Convert precipitation in mm to yearly rainfall estimate (very rough)
            final dailyPrecip = current['precip'] ?? 0;
            final estimatedYearlyRainfall = (dailyPrecip * 365).toStringAsFixed(
              0,
            );
            rainfallController.text = estimatedYearlyRainfall;
          }
        }
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      // Don't show snackbar here, use the default values instead
    } finally {
      setState(() {
        isLoadingWeather = false;
      });
    }
  }

  Future<void> _fetchSoilData(double lat, double lon) async {
    setState(() {
      isLoadingSoil = true;
    });

    try {
      // Fetch soil type
      final typeData = await _soilService.getSoilType(lat, lon, topK: 3);

      // Fetch soil properties
      final propertiesData = await _soilService.getSoilProperties(
        lat,
        lon,
        depths: ['0-30cm'],
        properties: ['phh2o', 'nitrogen', 'clay', 'sand', 'silt'],
        values: ['mean'],
      );

      setState(() {
        soilTypeData = typeData;
        soilData = propertiesData;

        // Extract soil type
        if (typeData.containsKey('properties') &&
            typeData['properties'].containsKey('most_probable_soil_type')) {
          soilType = typeData['properties']['most_probable_soil_type'];
        }

        // Extract soil properties and update form fields
        if (propertiesData.containsKey('properties') &&
            propertiesData['properties'].containsKey('layers')) {
          final layers = propertiesData['properties']['layers'];
          if (layers is List && layers.isNotEmpty) {
            for (var layer in layers) {
              if (layer.containsKey('name') &&
                  layer['name'] == '0-30cm' &&
                  layer.containsKey('properties')) {
                final props = layer['properties'];

                // Update pH controller
                if (props.containsKey('phh2o') &&
                    props['phh2o'].containsKey('mean')) {
                  phController.text = props['phh2o']['mean'].toString();
                }

                // Update nitrogen controller
                if (props.containsKey('nitrogen') &&
                    props['nitrogen'].containsKey('mean')) {
                  nController.text =
                      (props['nitrogen']['mean'] * 100).toString();
                }

                // You might need approximations for P and K as they might not be directly available
                // For demo purposes, we'll use calculated values based on soil composition
                if (props.containsKey('clay') &&
                    props['clay'].containsKey('mean') &&
                    props.containsKey('sand') &&
                    props['sand'].containsKey('mean') &&
                    props.containsKey('silt') &&
                    props['silt'].containsKey('mean')) {
                  // This is a rough approximation - in a real app you'd use a more accurate model
                  double clay = props['clay']['mean'];
                  double sand = props['sand']['mean'];
                  double silt = props['silt']['mean'];

                  // Rough approximation of P and K based on soil composition
                  // These are not scientifically accurate, just for demonstration
                  double pEstimate = clay * 0.5 + silt * 0.3;
                  double kEstimate = clay * 0.8 + silt * 0.2;

                  // Update P and K controllers with estimated values
                  pController.text = (pEstimate * 100).toStringAsFixed(0);
                  kController.text = (kEstimate * 100).toStringAsFixed(0);

                  // Store soil properties for display
                  soilProperties = {
                    'clay': clay,
                    'sand': sand,
                    'silt': silt,
                    'ph': props['phh2o']['mean'],
                    'nitrogen': props['nitrogen']['mean'],
                  };
                }
              }
            }
          }
        }
      });
    } catch (e) {
      print('Error fetching soil data: $e');
      // If fail to fetch soil data, use default soil parameters instead
      // Don't show snackbar here
    } finally {
      setState(() {
        isLoadingSoil = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Crop Recomendation'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Region Selection Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Region',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRegion,
                            isExpanded: true,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: BorderRadius.circular(8),
                            items:
                                [
                                  'North India',
                                  'South India',
                                  'East India',
                                  'West India',
                                  'Central India',
                                  'Default',
                                ].map((String region) {
                                  return DropdownMenuItem<String>(
                                    value: region,
                                    child: Text(region),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedRegion = newValue;
                                  _populateDefaultSoilParameters();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location and weather card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Weather & Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed:
                                isLoadingWeather ? null : _getCurrentLocation,
                            tooltip: 'Refresh data',
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red[400],
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  labelText: 'Location',
                                  border: InputBorder.none,
                                  hintText: 'Enter your location',
                                ),
                                onFieldSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _fetchWeatherData(value);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                              ),
                              onPressed:
                                  isLoadingWeather ? null : _getCurrentLocation,
                              tooltip: 'Use current location',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (isLoadingWeather)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (weatherData != null &&
                          weatherData!.containsKey('current'))
                        _buildWeatherInfo()
                      else
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Weather data not available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Default values will be used',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Soil information card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.landscape, color: Colors.brown[700]),
                          SizedBox(width: 8),
                          Text(
                            'Soil Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (isLoadingSoil)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (soilType != null)
                        _buildSoilInfo()
                      else
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.landscape,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Using default soil parameters for $_selectedRegion',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Soil and Climate Parameters Form Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Crop Parameters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Divider with label
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'SOIL NUTRIENTS',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // N, P, K inputs
                        Container(
                          width: 300,
                          height: 350,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.green[50],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.eco, color: Colors.green),
                                        SizedBox(height: 8),
                                        Text(
                                          'Nitrogen (N)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        TextFormField(
                                          controller: nController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                            suffixText: 'kg/ha',
                                          ),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          validator:
                                              (value) =>
                                                  value?.isEmpty ?? true
                                                      ? 'Required'
                                                      : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.orange[50],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.grain, color: Colors.orange),
                                        SizedBox(height: 8),
                                        Text(
                                          'Phosphorus (P)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        TextFormField(
                                          controller: pController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                            suffixText: 'kg/ha',
                                          ),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          validator:
                                              (value) =>
                                                  value?.isEmpty ?? true
                                                      ? 'Required'
                                                      : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.purple[50],
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.spa, color: Colors.purple),
                                        SizedBox(height: 8),
                                        Text(
                                          'Potassium (K)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        TextFormField(
                                          controller: kController,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                            isDense: true,
                                            suffixText: 'kg/ha',
                                          ),
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          validator:
                                              (value) =>
                                                  value?.isEmpty ?? true
                                                      ? 'Required'
                                                      : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // pH value
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blue[50],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.science, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Soil pH',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Acidity/alkalinity level of soil',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  width: 100,
                                  child: TextFormField(
                                    controller: phController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider with label
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'CLIMATE CONDITIONS',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Temperature and humidity
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.red[50],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.thermostat, color: Colors.red),
                                      SizedBox(height: 8),
                                      Text(
                                        'Temperature',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextFormField(
                                        controller: tempController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                          suffixText: '°C',
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        validator:
                                            (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Required'
                                                    : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.blue[50],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.water_drop,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Humidity',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      TextFormField(
                                        controller: humidityController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                          suffixText: '%',
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        validator:
                                            (value) =>
                                                value?.isEmpty ?? true
                                                    ? 'Required'
                                                    : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Rainfall
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.teal[50],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.grain, color: Colors.teal),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Annual Rainfall',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Total rainfall per year',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  width: 100,
                                  child: TextFormField(
                                    controller: rainfallController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                      suffixText: 'mm',
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    validator:
                                        (value) =>
                                            value?.isEmpty ?? true
                                                ? 'Required'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _interpreter == null ? null : _predictCrop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child:
                              isLoading
                                  ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'RECOMMEND SUITABLE CROPS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (recommendedCrop != null) ...[
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _animation,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.agriculture, color: Colors.green[700]),
                              SizedBox(width: 8),
                              Text(
                                'Recommended Crop',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green[700]!,
                                  Colors.green[600]!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  recommendedCrop!.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    'Confidence: ${(confidence! * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (allScores != null && allScores!.length > 1) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Alternative Crops',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(() {
                              final list =
                                  allScores!.entries
                                      .where(
                                        (entry) => entry.key != recommendedCrop,
                                      )
                                      .toList();
                              list.sort((a, b) => b.value.compareTo(a.value));
                              return list
                                  .take(3)
                                  .map(
                                    (entry) => Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green[100]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.eco,
                                                color: Colors.green[300],
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              '${(entry.value * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                            }()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final current = weatherData!['current'];
    final location = weatherData!['location'];

    String locationText = '';
    if (location != null) {
      final name = location['name'];
      final region = location['region'];
      final country = location['country'];
      locationText =
          '$name, ${region != null && region.isNotEmpty ? '$region, ' : ''}$country';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationText.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              locationText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherInfoItem(
                Icons.thermostat,
                '${current['temperature']}°C',
                'Temperature',
                Colors.orange[200]!,
              ),
              _weatherInfoItem(
                Icons.water_drop,
                '${current['humidity']}%',
                'Humidity',
                Colors.lightBlue[100]!,
              ),
              _weatherInfoItem(
                Icons.grain,
                '${current['precip']} mm',
                'Precip',
                Colors.teal[100]!,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSoilInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape, color: Colors.brown, size: 16),
              SizedBox(width: 6),
              Text(
                'Soil Type: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              Text(
                soilType ?? 'Unknown',
                style: TextStyle(color: Colors.brown[800]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (soilProperties != null) ...[
          Text(
            'Soil Composition',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.brown[800],
            ),
          ),
          const SizedBox(height: 8),

          // Soil composition bar chart
          Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.1),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Row(
                children: [
                  Expanded(
                    flex: ((soilProperties!['clay'] ?? 0) * 100).round(),
                    child: Container(color: Colors.brown[700]),
                  ),
                  Expanded(
                    flex: ((soilProperties!['silt'] ?? 0) * 100).round(),
                    child: Container(color: Colors.brown[400]),
                  ),
                  Expanded(
                    flex: ((soilProperties!['sand'] ?? 0) * 100).round(),
                    child: Container(color: Colors.amber[300]),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _soilLegendItem(
                'Clay',
                Colors.brown[700]!,
                '${((soilProperties!['clay'] ?? 0) * 100).toStringAsFixed(1)}%',
              ),
              SizedBox(width: 16),
              _soilLegendItem(
                'Silt',
                Colors.brown[400]!,
                '${((soilProperties!['silt'] ?? 0) * 100).toStringAsFixed(1)}%',
              ),
              SizedBox(width: 16),
              _soilLegendItem(
                'Sand',
                Colors.amber[300]!,
                '${((soilProperties!['sand'] ?? 0) * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Other soil properties
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.brown[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _soilPropertyItem(
                  'pH Level',
                  (soilProperties!['ph'] ?? 0).toStringAsFixed(1),
                  Icons.science,
                  Colors.purple[700]!,
                ),
                _soilPropertyItem(
                  'Nitrogen',
                  '${((soilProperties!['nitrogen'] ?? 0) * 100).toStringAsFixed(1)}%',
                  Icons.grass,
                  Colors.green[700]!,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _soilLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $percentage',
          style: TextStyle(fontSize: 12, color: Colors.brown[800]),
        ),
      ],
    );
  }

  Widget _soilPropertyItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _weatherInfoItem(
    IconData icon,
    String value,
    String label,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:farmer_consumer_marketplace/services/weather_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';


// class CropRecommendationScreen extends StatefulWidget {
//   const CropRecommendationScreen({super.key});

//   @override
//   State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
// }

// class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
//   final _formKey = GlobalKey<FormState>();
  
//   // Form controllers
//   final nController = TextEditingController();
//   final pController = TextEditingController();
//   final kController = TextEditingController();
//   final tempController = TextEditingController();
//   final humidityController = TextEditingController();
//   final phController = TextEditingController();
//   final rainfallController = TextEditingController();
//   final locationController = TextEditingController();
  
//   // Prediction results
//   String? recommendedCrop;
//   double? confidence;
//   Map<String, double>? allScores;
//   bool isLoading = false;
//   bool isLoadingWeather = false;
  
//   // Weather data
//   Map<String, dynamic>? weatherData;
//   String? locationName;
//   Position? currentPosition;
  
//   // Model
//   Interpreter? _interpreter;
//   Map<String, dynamic>? _metadata;
  
//   // Weather service
//   final WeatherService _weatherService = WeatherService();
  
//   @override
//   void initState() {
//     super.initState();
//     _loadModel();
//     _getCurrentLocation();
//   }
  
//   @override
//   void dispose() {
//     _interpreter?.close();
//     nController.dispose();
//     pController.dispose();
//     kController.dispose();
//     tempController.dispose();
//     humidityController.dispose();
//     phController.dispose();
//     rainfallController.dispose();
//     locationController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _loadModel() async {
//     try {
//       // Load the model
//       final interpreterOptions = InterpreterOptions();
//       _interpreter = await Interpreter.fromAsset(
//         'assets/crop_recommendation_model.tflite',
//         options: interpreterOptions,
//       );
      
//       // Load metadata
//       final metadataString = await rootBundle.loadString('assets/crop_model_metadata.json');
//       _metadata = jsonDecode(metadataString);
      
//       print('Model loaded successfully');
//     } catch (e) {
//       print('Error loading model: $e');
//     }
//   }
  
//   // Location permission and handling
//   Future<bool> _handleLocationPermission() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location services are disabled. Please enable the services')),
//       );
//       return false;
//     }
    
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permissions are denied')),
//         );
//         return false;
//       }
//     }
    
//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
//       );
//       return false;
//     }
    
//     return true;
//   }

//   Future<void> _getCurrentLocation() async {
//     final hasPermission = await _handleLocationPermission();
    
//     if (!hasPermission) return;
    
//     setState(() {
//       isLoadingWeather = true;
//     });
    
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
      
//       setState(() {
//         currentPosition = position;
//       });
      
//       // Get address from location
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude, 
//         position.longitude,
//       );
      
//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         String cityName = place.locality ?? '';
//         String countryName = place.country ?? '';
        
//         setState(() {
//           locationName = cityName.isNotEmpty ? "$cityName, $countryName" : countryName;
//           locationController.text = locationName ?? '';
//         });
        
//         // Get weather data for the location
//         if (locationName != null && locationName!.isNotEmpty) {
//           await _fetchWeatherData(locationName!);
//         }
//       }
//     } catch (e) {
//       print('Error getting location: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error getting location: $e')),
//       );
//     } finally {
//       setState(() {
//         isLoadingWeather = false;
//       });
//     }
//   }
  
//   Future<void> _fetchWeatherData(String location) async {
//     setState(() {
//       isLoadingWeather = true;
//     });
    
//     try {
//       final data = await _weatherService.getCurrentWeather(location);
      
//       setState(() {
//         weatherData = data;
        
//         // Update the form fields with weather data
//         if (data.containsKey('current')) {
//           final current = data['current'];
//           tempController.text = current['temperature']?.toString() ?? '';
//           humidityController.text = current['humidity']?.toString() ?? '';
          
//           // Estimated rainfall from precipitation (very rough approximation)
//           // Adjust this logic if your API provides better rainfall data
//           if (current.containsKey('precip')) {
//             // Convert precipitation in mm to yearly rainfall estimate (very rough)
//             final dailyPrecip = current['precip'] ?? 0;
//             final estimatedYearlyRainfall = (dailyPrecip * 365).toStringAsFixed(0);
//             rainfallController.text = estimatedYearlyRainfall;
//           }
//         }
//       });
//     } catch (e) {
//       print('Error fetching weather data: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching weather data: $e')),
//       );
//     } finally {
//       setState(() {
//         isLoadingWeather = false;
//       });
//     }
//   }
  
//   Future<void> _predictCrop() async {
//     if (_formKey.currentState?.validate() != true || _interpreter == null || _metadata == null) {
//       return;
//     }
    
//     setState(() {
//       isLoading = true;
//     });
    
//     try {
//       // Get values from form
//       final n = double.parse(nController.text);
//       final p = double.parse(pController.text);
//       final k = double.parse(kController.text);
//       final temp = double.parse(tempController.text);
//       final humidity = double.parse(humidityController.text);
//       final ph = double.parse(phController.text);
//       final rainfall = double.parse(rainfallController.text);
      
//       // Preprocess input
//       final input = [n, p, k, temp, humidity, ph, rainfall];
//       final processedInput = _preprocess(input);
      
//       // Run inference
//       final output = List<List<double>>.filled(
//         1, 
//         List<double>.filled(_metadata!['crop_dict'].length, 0)
//       );
      
//       _interpreter!.run([processedInput], output);
      
//       // Process results
//       final predictions = output[0];
//       int maxIndex = 0;
//       double maxValue = predictions[0];
      
//       for (int i = 1; i < predictions.length; i++) {
//         if (predictions[i] > maxValue) {
//           maxValue = predictions[i];
//           maxIndex = i;
//         }
//       }
      
//       // Convert back to crop name (adding 1 because indices are 1-based in metadata)
//       final cropIndex = (maxIndex + 1).toString();
//       final cropDictReverse = Map<String, String>.from(_metadata!['crop_dict_reverse']);
      
//       setState(() {
//         recommendedCrop = cropDictReverse[cropIndex] ?? 'Unknown';
//         confidence = maxValue;
        
//         // Get all scores
//         allScores = {};
//         for (int i = 0; i < predictions.length; i++) {
//           final cropKey = (i + 1).toString();
//           if (cropDictReverse.containsKey(cropKey)) {
//             allScores![cropDictReverse[cropKey]!] = predictions[i];
//           }
//         }
        
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       print('Error during prediction: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
  
//   List<double> _preprocess(List<double> input) {
//     final inputMean = List<double>.from(_metadata!['input_mean']);
//     final inputStd = List<double>.from(_metadata!['input_std']);
    
//     List<double> normalized = [];
//     for (int i = 0; i < input.length; i++) {
//       normalized.add((input[i] - inputMean[i]) / inputStd[i]);
//     }
    
//     return normalized;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
     
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Location and weather card
//             Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Weather Information',
//                             style: Theme.of(context).textTheme.titleLarge,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.refresh),
//                           onPressed: isLoadingWeather ? null : _getCurrentLocation,
//                           tooltip: 'Refresh weather data',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
                    
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: locationController,
//                             decoration: const InputDecoration(
//                               labelText: 'Location',
//                               border: OutlineInputBorder(),
//                               prefixIcon: Icon(Icons.location_on),
//                             ),
//                             readOnly: false,
//                             onFieldSubmitted: (value) {
//                               if (value.isNotEmpty) {
//                                 _fetchWeatherData(value);
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           icon: const Icon(Icons.my_location),
//                           onPressed: isLoadingWeather ? null : _getCurrentLocation,
//                           tooltip: 'Use current location',
//                         ),
//                       ],
//                     ),
                    
//                     const SizedBox(height: 16),
                    
//                     if (isLoadingWeather)
//                       const Center(
//                         child: Padding(
//                           padding: EdgeInsets.all(8.0),
//                           child: CircularProgressIndicator(),
//                         ),
//                       )
//                     else if (weatherData != null && weatherData!.containsKey('current'))
//                       _buildWeatherInfo(),
//                   ],
//                 ),
//               ),
//             ),
            
//             const SizedBox(height: 16),
            
//             // Input parameters card
//             Card(
//               elevation: 4,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       Text(
//                         'Soil Parameters',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 20),
                      
//                       // N, P, K inputs
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: nController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Nitrogen (N)',
//                                 border: OutlineInputBorder(),
//                                 suffixText: 'kg/ha',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: TextFormField(
//                               controller: pController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Phosphorus (P)',
//                                 border: OutlineInputBorder(),
//                                 suffixText: 'kg/ha',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: TextFormField(
//                               controller: kController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Potassium (K)',
//                                 border: OutlineInputBorder(),
//                                 suffixText: 'kg/ha',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 16),
                      
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: phController,
//                               decoration: const InputDecoration(
//                                 labelText: 'pH',
//                                 border: OutlineInputBorder(),
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       Text(
//                         'Climate Parameters',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 16),
                      
//                       // Temperature and humidity
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: tempController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Temperature',
//                                 border: OutlineInputBorder(),
//                                 suffixText: '°C',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: TextFormField(
//                               controller: humidityController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Humidity',
//                                 border: OutlineInputBorder(),
//                                 suffixText: '%',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 16),
                      
//                       Row(
//                         children: [
//                           Expanded(
//                             child: TextFormField(
//                               controller: rainfallController,
//                               decoration: const InputDecoration(
//                                 labelText: 'Rainfall',
//                                 border: OutlineInputBorder(),
//                                 suffixText: 'mm',
//                               ),
//                               keyboardType: TextInputType.number,
//                               validator: (value) => value?.isEmpty ?? true 
//                                 ? 'Required' : null,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 24),
                      
//                       ElevatedButton(
//                         onPressed: _interpreter == null ? null : _predictCrop,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).colorScheme.primary,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           minimumSize: const Size(double.infinity, 50),
//                         ),
//                         child: isLoading 
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text('Recommend Crop'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
            
//             if (recommendedCrop != null) ...[
//               const SizedBox(height: 24),
//               Card(
//                 elevation: 4,
//                 color: Theme.of(context).colorScheme.secondaryContainer,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Text(
//                         'Recommended Crop',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 16),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).colorScheme.primary,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Text(
//                               recommendedCrop!.toUpperCase(),
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Confidence: ${(confidence! * 100).toStringAsFixed(2)}%',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
                      
//                       if (allScores != null && allScores!.length > 1) ...[
//                         const SizedBox(height: 16),
//                         Text(
//                           'Alternative Options',
//                           style: Theme.of(context).textTheme.titleMedium,
//                         ),
//                         const SizedBox(height: 8),
//                         ...(() {
//                           final list = allScores!.entries
//                               .where((entry) => entry.key != recommendedCrop)
//                               .toList();
//                           list.sort((a, b) => b.value.compareTo(a.value));
//                           return list.take(3).map((entry) => Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 4),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(
//                                       entry.key,
//                                       style: const TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     Text(
//                                       '${(entry.value * 100).toStringAsFixed(2)}%',
//                                     ),
//                                   ],
//                                 ),
//                               ));
//                         }()),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildWeatherInfo() {
//     final current = weatherData!['current'];
//     final location = weatherData!['location'];
    
//     String locationText = '';
//     if (location != null) {
//       final name = location['name'];
//       final region = location['region'];
//       final country = location['country'];
//       locationText = '$name, ${region != null && region.isNotEmpty ? '$region, ' : ''}$country';
//     }
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (locationText.isNotEmpty) ...[
//           Text(
//             locationText,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//         ],
        
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _weatherInfoItem(
//               Icons.thermostat,
//               '${current['temperature']}°C',
//               'Temperature',
//               Colors.orange,
//             ),
//             _weatherInfoItem(
//               Icons.water_drop,
//               '${current['humidity']}%',
//               'Humidity',
//               Colors.blue,
//             ),
//             _weatherInfoItem(
//               Icons.air,
//               '${current['wind_speed']} km/h',
//               'Wind',
//               Colors.teal,
//             ),
//           ],
//         ),
        
//         const SizedBox(height: 8),
        
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _weatherInfoItem(
//               Icons.cloud,
//               '${current['cloudcover']}%',
//               'Cloud Cover',
//               Colors.grey,
//             ),
//             _weatherInfoItem(
//               Icons.water,
//               '${current['precip']} mm',
//               'Precipitation',
//               Colors.lightBlue,
//             ),
//             _weatherInfoItem(
//               Icons.visibility,
//               '${current['visibility']} km',
//               'Visibility',
//               Colors.purple,
//             ),
//           ],
//         ),
        
//         const SizedBox(height: 16),
        
//         Text(
//           'Weather data is used to pre-fill temperature, humidity, and rainfall parameters.',
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//             fontStyle: FontStyle.italic,
//           ),
//         ),
//       ],
//     );
//   }
  
//   Widget _weatherInfoItem(IconData icon, String value, String label, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[700],
//           ),
//         ),
//       ],
//     );
//   }
// }
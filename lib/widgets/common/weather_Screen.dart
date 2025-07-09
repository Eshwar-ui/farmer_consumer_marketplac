import 'package:farmer_consumer_marketplace/widgets/common/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:farmer_consumer_marketplace/models/weather_model.dart';
import 'package:farmer_consumer_marketplace/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  late Future<WeatherInfo> _weatherFuture;
  final TextEditingController _locationController = TextEditingController();
  String _currentLocation = 'New Delhi';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check location permission status
      var status = await Permission.location.status;
      
      if (status.isDenied) {
        // Request location permission
        status = await Permission.location.request();
      }
      
      if (status.isGranted) {
        await _getCurrentLocation();
      } else {
        // User denied permission, use default location
        setState(() {
          _errorMessage = 'Location permission denied. Using default location.';
          _fetchWeatherData();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing location: $e';
        _fetchWeatherData();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Use coordinates for weather lookup
      setState(() {
        _currentLocation = '${position.latitude},${position.longitude}';
      });
      
      _fetchWeatherData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not get current location: $e';
        _fetchWeatherData();
      });
    }
  }

  void _fetchWeatherData() {
    setState(() {
      _weatherFuture = _getWeatherInfo();
    });
  }

  Future<WeatherInfo> _getWeatherInfo() async {
    try {
      final weatherData = await _weatherService.getCurrentWeather(_currentLocation);
      return WeatherInfo.fromJson(weatherData);
    } catch (e) {
      print('Error fetching weather data: $e');
      // Return demo data if API fails
      return WeatherInfo.demo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Weather Information',
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _checkLocationPermission,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchWeatherData,
          ),
        ],
      ),
    
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.yellow[100],
              padding: EdgeInsets.all(8.0),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter location (e.g., New Delhi)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    if (_locationController.text.isNotEmpty) {
                      setState(() {
                        _currentLocation = _locationController.text;
                      });
                      _fetchWeatherData();
                    }
                  },
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : FutureBuilder<WeatherInfo>(
                    future: _weatherFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 60, color: Colors.red),
                                SizedBox(height: 16),
                                Text(
                                  'Error loading weather data',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchWeatherData,
                                  child: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final weather = snapshot.data!;
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLocationInfo(weather),
                              SizedBox(height: 24.0),
                              _buildCurrentWeather(weather),
                              SizedBox(height: 24.0),
                              _buildWeatherDetails(weather),
                              SizedBox(height: 24.0),
                              _buildAdditionalInfo(weather),
                            ],
                          ),
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No weather data available',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(WeatherInfo weather) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.location,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  '${weather.region}, ${weather.country}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Last updated: ${weather.observationTime}',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(WeatherInfo weather) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.temperature,
                  style: TextStyle(
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  weather.condition,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  'Feels like ${weather.feelsLike}',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            weather.weatherIcons.isNotEmpty
                ? Image.network(
                    weather.weatherIcons.first,
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.wb_sunny,
                        size: 80,
                        color: Colors.amber,
                      );
                    },
                  )
                : Icon(
                    Icons.wb_sunny,
                    size: 80,
                    color: Colors.amber,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherInfo weather) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Details',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _weatherDetailItem(Icons.opacity, 'Humidity', weather.humidity),
                _weatherDetailItem(Icons.water_drop, 'Rainfall', weather.rainfall),
                _weatherDetailItem(Icons.air, 'Wind', weather.windSpeed),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _weatherDetailItem(Icons.compress, 'Pressure', weather.pressure),
                _weatherDetailItem(Icons.visibility, 'Visibility', weather.visibility),
                _weatherDetailItem(Icons.wb_sunny, 'UV Index', weather.uvIndex),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 28.0),
        SizedBox(height: 8.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(WeatherInfo weather) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agriculture Tips',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            _buildAgricultureTip(
              Icons.water_drop,
              'Watering Advice',
              _getWateringAdvice(weather),
            ),
            Divider(),
            _buildAgricultureTip(
              Icons.pest_control,
              'Pest Alert',
              _getPestAlert(weather),
            ),
            Divider(),
            _buildAgricultureTip(
              Icons.agriculture,
              'Farming Tip',
              _getFarmingTip(weather),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgricultureTip(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 24.0),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWateringAdvice(WeatherInfo weather) {
    final rainfall = double.tryParse(weather.rainfall.replaceAll('mm', '')) ?? 0;
    final humidity = double.tryParse(weather.humidity.replaceAll('%', '')) ?? 0;
    
    if (rainfall > 5) {
      return 'Recent rainfall is sufficient. Skip watering today to avoid overwatering and potential root diseases.';
    } else if (humidity > 80) {
      return 'High humidity detected. Consider light watering or skip today depending on your crop requirements.';
    } else if (weather.condition.toLowerCase().contains('sunny') || 
              weather.condition.toLowerCase().contains('clear')) {
      return 'Clear weather with low rainfall. Ensure adequate irrigation, especially for water-intensive crops.';
    } else {
      return 'Moderate conditions. Follow your regular watering schedule based on crop type and growth stage.';
    }
  }

  String _getPestAlert(WeatherInfo weather) {
    final temperature = double.tryParse(weather.temperature.replaceAll('°C', '')) ?? 0;
    final humidity = double.tryParse(weather.humidity.replaceAll('%', '')) ?? 0;
    
    if (temperature > 28 && humidity > 70) {
      return 'High temperature and humidity conditions are favorable for fungal growth and insect proliferation. Monitor crops closely.';
    } else if (temperature > 30) {
      return 'High temperatures may lead to increased aphid and mite activity. Check undersides of leaves regularly.';
    } else if (humidity > 80) {
      return 'High humidity can promote fungal diseases. Ensure proper spacing between plants for ventilation.';
    } else {
      return 'Current conditions have moderate pest risk. Maintain regular monitoring practices.';
    }
  }

  String _getFarmingTip(WeatherInfo weather) {
    if (weather.condition.toLowerCase().contains('rain') || 
        weather.condition.toLowerCase().contains('drizzle')) {
      return 'Rainy conditions are good for transplanting seedlings. Avoid applying fertilizers as they may wash away.';
    } else if (weather.condition.toLowerCase().contains('sunny')) {
      return 'Sunny conditions are ideal for harvesting and drying crops. Consider mulching to retain soil moisture.';
    } else if (weather.condition.toLowerCase().contains('cloudy')) {
      return 'Cloudy weather is good for applying fertilizers and pesticides as there is less chance of evaporation.';
    } else {
      return 'Current weather is suitable for general farming activities. Follow crop-specific best practices.';
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
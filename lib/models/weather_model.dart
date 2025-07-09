class WeatherInfo {
  final String temperature;
  final String condition;
  final String rainfall;
  final String humidity;
  final String windSpeed;
  final String pressure;
  final String feelsLike;
  final String visibility;
  final String location;
  final String region;
  final String country;
  final String observationTime;
  final List<String> weatherIcons;
  final List<String> weatherDescriptions;
  final String uvIndex;

  WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.rainfall,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.feelsLike,
    required this.visibility,
    required this.location,
    required this.region,
    required this.country,
    required this.observationTime,
    required this.weatherIcons,
    required this.weatherDescriptions,
    required this.uvIndex,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final location = json['location'];
    
    List<String> icons = [];
    if (current['weather_icons'] != null) {
      icons = List<String>.from(current['weather_icons']);
    }
    
    List<String> descriptions = [];
    if (current['weather_descriptions'] != null) {
      descriptions = List<String>.from(current['weather_descriptions']);
    }
    
    return WeatherInfo(
      temperature: '${current['temperature']}°C',
      condition: descriptions.isNotEmpty ? descriptions.first : 'Unknown',
      rainfall: '${current['precip']}mm',
      humidity: '${current['humidity']}%',
      windSpeed: '${current['wind_speed']} km/h',
      pressure: '${current['pressure']} mb',
      feelsLike: '${current['feelslike']}°C',
      visibility: '${current['visibility']} km',
      location: location['name'],
      region: location['region'],
      country: location['country'],
      observationTime: current['observation_time'],
      weatherIcons: icons,
      weatherDescriptions: descriptions,
      uvIndex: current['uv_index'].toString(),
    );
  }

  // For demo/fallback purposes
  factory WeatherInfo.demo() {
    return WeatherInfo(
      temperature: '32°C',
      condition: 'Sunny',
      rainfall: '0mm',
      humidity: '65%',
      windSpeed: '5 km/h',
      pressure: '1010 mb',
      feelsLike: '34°C',
      visibility: '10 km',
      location: 'New Delhi',
      region: 'Delhi',
      country: 'India',
      observationTime: '12:00 PM',
      weatherIcons: ['https://assets.weatherstack.com/images/wsymbols01_png_64/wsymbol_0001_sunny.png'],
      weatherDescriptions: ['Sunny'],
      uvIndex: '6',
    );
  }
}
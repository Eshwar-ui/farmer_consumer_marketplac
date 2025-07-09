import 'dart:convert';
import 'package:http/http.dart' as http;

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
        Uri.parse('$baseUrl/forecast?access_key=$apiKey&query=$query&forecast_days=$days'),
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
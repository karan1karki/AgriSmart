// lib/core/network/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agrismart/core/database/db_helper.dart';


class WeatherService {
  // Coordinates mapper for major farming districts in Nepal as a fallback
  static const Map<String, Map<String, double>> _districtCoordinates = {
    'kathmandu': {'lat': 27.7172, 'lon': 85.3240},
    'bharatpur': {'lat': 27.6744, 'lon': 84.4383},
    'chitwan': {'lat': 27.5341, 'lon': 84.4525},
    'pokhara': {'lat': 28.2096, 'lon': 83.9856},
  };

  Future<Map<String, dynamic>> fetchLocalWeather() async {
    try {
      // 1. Fetch user profile from SQLite to find their location string
      final List<Map<String, dynamic>> users = await DBHelper().getData('user');
      
      String location = 'Bharatpur'; // Default fallback location
      if (users.isNotEmpty && users.first['location'] != null) {
        location = users.first['location'];
      }

      // 2. Resolve coordinates based on district string name matching
      final cleanLocationKey = location.toLowerCase().trim();
      double lat = _districtCoordinates[cleanLocationKey]?['lat'] ?? 27.6744; 
      double lon = _districtCoordinates[cleanLocationKey]?['lon'] ?? 84.4383;

      // 3. Make HTTP request call to open weather data endpoint
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true'
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentWeather = data['current_weather'];
        
        return {
          'location': location,
          'temp': '${currentWeather['temperature']}°C',
          'wind': '${currentWeather['windspeed']} km/h',
          'isLoaded': true
        };
      }
    } catch (e) {
      print("Error fetching dynamic weather context: $e");
    }
    
    return {'location': 'Nepal', 'temp': '--°C', 'wind': '--', 'isLoaded': false};
  }
} 
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  // Cached weather data
  Map<String, dynamic>? _cachedCurrentWeather;
  Map<String, dynamic>? _cachedHourlyData;
  Map<String, dynamic>? _cachedDailyData;
  DateTime? _lastFetchTime;

  // Location
  final double latitude = 19.0760; // Mumbai
  final double longitude = 72.8777;
  final String cityName = 'Mumbai';

  // Cache duration (5 minutes)
  static const cacheDuration = Duration(minutes: 5);

  Future<Map<String, dynamic>> fetchWeatherData({bool forceRefresh = false}) async {
    print('🌤️ Fetching weather data...');

    // Return cached data if available and not expired
    if (!forceRefresh &&
        _cachedCurrentWeather != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < cacheDuration) {
      print('✅ Returning cached weather data');
      return {
        'current': _cachedCurrentWeather,
        'hourly': _cachedHourlyData,
        'daily': _cachedDailyData,
        'city': cityName,
      };
    }

    try {
      print('🌐 Making API call to Open-Meteo...');
      final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weathercode&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max&timezone=auto',
      )).timeout(Duration(seconds: 10));

      print('📡 API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received successfully');

        // Cache the data
        _cachedCurrentWeather = data['current_weather'];
        _cachedHourlyData = data['hourly'];
        _cachedDailyData = data['daily'];
        _lastFetchTime = DateTime.now();

        print('🌡️ Temperature: ${_cachedCurrentWeather!['temperature']}°C');

        return {
          'current': _cachedCurrentWeather,
          'hourly': _cachedHourlyData,
          'daily': _cachedDailyData,
          'city': cityName,
        };
      } else {
        print('❌ API Error: Status code ${response.statusCode}');
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching weather: $e');
      throw Exception('Error fetching weather: $e');
    }
  }

  // Get current temperature
  String getCurrentTemperature() {
    if (_cachedCurrentWeather != null) {
      return '${_cachedCurrentWeather!['temperature']?.round() ?? '--'}°C';
    }
    return '--°C';
  }

  // Get current humidity (from hourly data - first entry)
  String getCurrentHumidity() {
    if (_cachedHourlyData != null && _cachedHourlyData!['relative_humidity_2m'] != null) {
      return '${_cachedHourlyData!['relative_humidity_2m'][0] ?? '--'}%';
    }
    return '--%';
  }

  // Get precipitation probability
  String getPrecipitation() {
    if (_cachedHourlyData != null && _cachedHourlyData!['precipitation_probability'] != null) {
      return '${_cachedHourlyData!['precipitation_probability'][0] ?? 0}%';
    }
    return '0%';
  }

  // Get wind speed
  String getWindSpeed() {
    if (_cachedCurrentWeather != null) {
      return '${_cachedCurrentWeather!['windspeed']?.round() ?? '--'} km/h';
    }
    return '-- km/h';
  }

  // Get city name
  String getCityName() {
    return cityName;
  }

  // Clear cache
  void clearCache() {
    _cachedCurrentWeather = null;
    _cachedHourlyData = null;
    _cachedDailyData = null;
    _lastFetchTime = null;
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weatherservices.dart'; // Import weather service

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String cityName = 'Mumbai';
  Map<String, dynamic>? currentWeather;
  Map<String, dynamic>? hourlyData;
  Map<String, dynamic>? dailyData;
  bool isLoading = true;
  String errorMessage = '';

  final double latitude = 19.0760;
  final double longitude = 72.8777;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weathercode&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max&timezone=auto',
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentWeather = data['current_weather'];
          hourlyData = data['hourly'];
          dailyData = data['daily'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load weather data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode <= 3) return Icons.wb_cloudy;
    if (weatherCode <= 48) return Icons.cloud;
    if (weatherCode <= 67) return Icons.grain;
    if (weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode <= 82) return Icons.water_drop;
    if (weatherCode <= 95) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  String _getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 82) return 'Rain Showers';
    if (weatherCode <= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  String _formatHour(String time) {
    final hour = DateTime.parse(time).hour;
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getDayName(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    if (date.day == now.day) return 'Today';
    if (date.day == now.day + 1) return 'Tomorrow';

    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF7E8BA3)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      )
          : errorMessage.isNotEmpty
          ? Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF7E8BA3)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.white),
              const SizedBox(height: 20),
              Text(errorMessage, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchWeatherData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getGradientColors(currentWeather?['weathercode'] ?? 0),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              cityName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white, size: 24),
                        ),
                        onPressed: fetchWeatherData,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Main Temperature Display
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${currentWeather?['temperature']?.round() ?? '--'}°',
                          style: const TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getWeatherIcon(currentWeather?['weathercode'] ?? 0),
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _getWeatherDescription(currentWeather?['weathercode'] ?? 0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.air, color: Colors.white.withOpacity(0.9), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Wind: ${currentWeather?['windspeed']?.round() ?? '--'} km/h',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Hourly Forecast
                  const Text(
                    'HOURLY FORECAST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final temp = hourlyData?['temperature_2m'][index];
                        final time = hourlyData?['time'][index];
                        final humidity = hourlyData?['relative_humidity_2m'][index];
                        final precipitation = hourlyData?['precipitation_probability'][index];
                        final weatherCode = hourlyData?['weathercode'][index];

                        return Container(
                          width: 75,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? Colors.white.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                _formatHour(time ?? ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                _getWeatherIcon(weatherCode ?? 0),
                                color: Colors.white,
                                size: 32,
                              ),
                              Text(
                                '${temp?.round() ?? '--'}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.water_drop,
                                      size: 14,
                                      color: Colors.lightBlueAccent.withOpacity(0.8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${precipitation ?? 0}%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Additional Weather Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Humidity',
                          '${hourlyData?['relative_humidity_2m'][0] ?? '--'}%',
                          Icons.water_drop,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInfoCard(
                          'Precipitation',
                          '${hourlyData?['precipitation_probability'][0] ?? 0}%',
                          Icons.grain,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 7-Day Forecast
                  const Text(
                    '7-DAY FORECAST',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final tempMax = dailyData?['temperature_2m_max'][index];
                        final tempMin = dailyData?['temperature_2m_min'][index];
                        final date = dailyData?['time'][index];
                        final weatherCode = dailyData?['weathercode'][index];
                        final precipitation = dailyData?['precipitation_probability_max'][index];

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < 6
                                  ? BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  _getDayName(date ?? ''),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    _getWeatherIcon(weatherCode ?? 0),
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.water_drop,
                                      size: 16,
                                      color: Colors.lightBlueAccent.withOpacity(0.8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${precipitation ?? 0}%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${tempMax?.round() ?? '--'}°',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${tempMin?.round() ?? '--'}°',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(int weatherCode) {
    if (weatherCode == 0) {
      // Clear sky - bright blue
      return [const Color(0xFF2E7EE8), const Color(0xFF4B9FF2), const Color(0XFFC8E6C9)];
    } else if (weatherCode <= 3) {
      // Partly cloudy
      return [const Color(0xFF43A047), const Color(0xFF4CAF50), const Color(0XFFC8E6C9)];
    } else if (weatherCode <= 67) {
      // Rainy - darker blue/grey
      return [const Color(0xFF2C3E50), const Color(0xFF34495E), const Color(0xFF5D6D7E)];
    } else if (weatherCode <= 95) {
      // Stormy - dark
      return [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)];
    }
    // Default
    return [const Color(0xFF1E3C72), const Color(0xFF2A5298), const Color(0xFF7E8BA3)];
  }
}
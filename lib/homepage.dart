import 'package:ag_pro/auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'planthealth.dart';
import 'soilhealth.dart';
import 'menupage.dart';
import 'weatherpage.dart';
import 'weatherservices.dart'; // ADDED: Import weather service
import 'dart:async';

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // Auto-refreshing card system variables
  int _currentCardIndex = 0;
  Timer? _cardTimer;
  final PageController _cardPageController = PageController();

  // ADDED: Weather service and variables
  final WeatherService _weatherService = WeatherService();
  String _temperature = '--°C';
  String _humidity = '--%';
  String _rainfall = '0%';
  String _windSpeed = '-- km/h';
  String _cityName = 'Loading...';
  bool _weatherLoading = true;

  // Card data
  final List<Map<String, dynamic>> _cards = [
    {
      'type': 'tip',
      'icon': Icons.lightbulb,
      'title': 'Farming Tip',
      'content': 'Water your crops early morning for better absorption',
      'color': Colors.orange,
    },
    {
      'type': 'weather',
      'icon': Icons.wb_sunny,
      'title': 'Weather Alert',
      'content': 'Perfect sunny day for outdoor farming activities',
      'color': Colors.blue,
    },
    {
      'type': 'soil',
      'icon': Icons.grass,
      'title': 'Soil Health',
      'content': 'Your soil pH is optimal at 6.5 - Great for most crops!',
      'color': Colors.green,
    },
    {
      'type': 'tip',
      'icon': Icons.eco,
      'title': 'Growth Tip',
      'content': 'Add organic compost to boost nitrogen levels',
      'color': Colors.teal,
    },
    {
      'type': 'weather',
      'icon': Icons.water_drop,
      'title': 'Humidity Check',
      'content': '60% humidity - Ideal conditions for plant growth',
      'color': Colors.indigo,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCardRotation();
    _loadWeatherData(); // ADDED: Load weather data on app start
  }

  // ADDED: Function to load weather data from API
  Future<void> _loadWeatherData() async {
    print('🏠 Homepage: Loading weather data...');

    setState(() {
      _weatherLoading = true;
    });

    try {
      final weatherData = await _weatherService.fetchWeatherData();
      print('✅ Homepage: Weather data received');
      print('Temperature: ${weatherData['current']['temperature']}');

      if (mounted) {
        setState(() {
          _temperature = '${weatherData['current']['temperature']?.round() ?? '--'}°C';
          _humidity = '${weatherData['hourly']['relative_humidity_2m'][0] ?? '--'}%';
          _rainfall = '${weatherData['hourly']['precipitation_probability'][0] ?? 0}%';
          _windSpeed = '${weatherData['current']['windspeed']?.round() ?? '--'} km/h';
          _cityName = weatherData['city'] ?? 'Mumbai';
          _weatherLoading = false;
        });
        print('✅ Homepage: Weather UI updated successfully');
      }
    } catch (e) {
      print('❌ Homepage: Error loading weather: $e');
      if (mounted) {
        setState(() {
          // Set fallback values if API fails
          _temperature = '28°C';
          _humidity = '65%';
          _rainfall = '5%';
          _windSpeed = '12 km/h';
          _cityName = 'Mumbai';
          _weatherLoading = false;
        });
      }

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load weather data'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cardTimer?.cancel();
    _cardPageController.dispose();
    super.dispose();
  }

  void _startCardRotation() {
    _cardTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentCardIndex = (_currentCardIndex + 1) % _cards.length;
        });

        _cardPageController.animateToPage(
          _currentCardIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Widget _buildAutoRefreshCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WeatherPage()),
        );
      },
      child: Container(
        height: 200,
        margin: EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: Colors.green[300],
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _cardPageController,
                itemCount: _cards.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentCardIndex = index;
                  });
                  print('Page changed to: $index');
                },
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            card['icon'],
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          card['title'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            card['content'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _cards.length,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: _currentCardIndex == index ? 20 : 6,
                      decoration: BoxDecoration(
                        color: _currentCardIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _cards[_currentCardIndex]['type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soilHealth(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(width: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        )
      ],
    );
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOut() {
    return ElevatedButton(
      onPressed: signOut,
      style: ElevatedButton.styleFrom(
        primary: Colors.red,
      ),
      child: Text('Logout'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('agp'),
      ),
      body: Center(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.green[300]),
                    height: 100,
                    padding: EdgeInsets.only(left: 50),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello User!',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 150),
                            Icon(Icons.person),
                          ],
                        )
                      ],
                    ),
                  ),
                  _buildAutoRefreshCard(),
                  SizedBox(height: 30),

                  // UPDATED: Weather card with real API data
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WeatherPage()),
                      );
                    },
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                      padding: EdgeInsets.all(30.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: _weatherLoading
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.green.shade700,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Loading weather...',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 10),
                            TextButton(
                              onPressed: _loadWeatherData,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Weather",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 18, color: Colors.green.shade900),
                                  SizedBox(width: 4),
                                  Text(
                                    _cityName, // CHANGED: Now from API
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  InkWell(
                                    onTap: _loadWeatherData,
                                    child: Icon(
                                      Icons.refresh,
                                      size: 18,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          SizedBox(height: 30),

                          // THIS IS THE PART YOU WANTED UPDATED!
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3,
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                // CHANGED: All values now from API
                                _weatherItem(
                                    Icons.thermostat, "Temperature", _temperature),
                                _weatherItem(
                                    Icons.water_drop, "Humidity", _humidity),
                                _weatherItem(Icons.grain, "Rainfall", _rainfall),
                                _weatherItem(Icons.air, "Wind", _windSpeed),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                  Container(
                    height: 250,
                    width: 400,
                    margin: EdgeInsets.symmetric(horizontal: 30.0),
                    padding: EdgeInsets.all(50.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.00),
                      color: Colors.green.shade100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil Health',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [],
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: Column(
                            children: [
                              _soilHealth("pH Level", "6.5"),
                              _soilHealth("Moisture", "45%"),
                              _soilHealth("Nitrogen (N)", "120 "),
                              _soilHealth("Phosphorus (P)", "50"),
                              _soilHealth("Potassium (K)", "80")
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
            PlantHealthPage(),
            SoilHealthPage(),
            MenuPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: GNav(
            color: Colors.black,
            activeColor: Colors.black,
            backgroundColor: Colors.green.shade100,
            gap: 8,
            haptic: true,
            padding: EdgeInsets.all(15),
            selectedIndex: _selectedIndex,
            onTabChange: _onTabChange,
            tabs: [
              GButton(
                icon: Icons.home,
                text: 'Home',
                textColor: Colors.black,
                backgroundColor: Colors.green[300],
                iconActiveColor: Colors.black,
              ),
              GButton(
                icon: Icons.eco,
                text: 'Plant Health',
                textColor: Colors.black,
                backgroundColor: Colors.green[300],
                iconActiveColor: Colors.black,
              ),
              GButton(
                icon: Icons.science,
                text: 'Soil and fertilizer',
                textColor: Colors.black,
                backgroundColor: Colors.green[300],
                iconActiveColor: Colors.black,
              ),
              GButton(
                icon: Icons.menu,
                text: 'Menu',
                textColor: Colors.black,
                backgroundColor: Colors.green[300],
                iconActiveColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget
Widget _weatherItem(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 24, color: Colors.green.shade800),
      SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ],
  );
}
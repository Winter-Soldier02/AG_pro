import 'package:ag_pro/auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'planthealth.dart';
import 'soilhealth.dart';
import 'menupage.dart';
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
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     spreadRadius: 3,
        //     blurRadius: 6,
        //   ),
        // ],
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
            // Main card content
            PageView.builder(
              controller: _cardPageController,
              itemCount: _cards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentCardIndex = index;
                });
                print('Page changed to: $index'); // Debug message
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

            // Progress indicator dots
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

            // Card type indicator
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
                  // Auto-refreshing card system
                  Container(

                    decoration: BoxDecoration(
                      color:Colors.green[300]
                    ),
                    height: 100,
                    padding: EdgeInsets.only(left:50),
                    child:
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [

                              Text('Hello User!',
                              style: TextStyle(fontSize: 20,
                              fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width:150),
                              Icon(Icons.person),
                            ],
                          )
                        ],
                      )
                  ),

                  _buildAutoRefreshCard(),

                  SizedBox(height: 30),

                  Container(
                    height: 250,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                    padding: EdgeInsets.all(30.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Column(
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
                                  "Green Valley, CA",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        SizedBox(height: 30),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              _weatherItem(
                                  Icons.thermostat, "Temperature", "25°C"),
                              _weatherItem(Icons.water_drop, "Humidity", "60%"),
                              _weatherItem(Icons.grain, "Rainfall", "5 mm"),
                              _weatherItem(Icons.air, "Wind", "10 km/h"),
                            ],
                          ),
                        ),
                      ],
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
                  // Container(
                  //   height: 250,
                  //   width: 400,
                  //   margin: EdgeInsets.symmetric(horizontal: 30.0),
                  //   padding: EdgeInsets.all(50.0),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(50.00),
                  //     color: Colors.green.shade100,
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         'Soil Health',
                  //         style: TextStyle(
                  //             fontSize: 20, fontWeight: FontWeight.bold),
                  //       ),
                  //       Row(
                  //         children: [],
                  //       ),
                  //       SizedBox(height: 20),
                  //       Expanded(
                  //         child: Column(
                  //           children: [
                  //             _soilHealth("pH Level", "6.5"),
                  //             _soilHealth("Moisture", "45%"),
                  //             _soilHealth("Nitrogen (N)", "120 "),
                  //             _soilHealth("Phosphorus (P)", "50"),
                  //             _soilHealth("Potassium (K)", "80")
                  //           ],
                  //         ),
                  //       )
                  //     ],
                  //   ),
                  // ),
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
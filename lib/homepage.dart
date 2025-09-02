import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:cupertino_icons/cupertino_icons.dart';




class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectedIndex=0;
  final PageController _pageController = PageController();

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }


  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Widget _soilHealth(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [Text(
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
            ),],
        )
      ],
    );
  }




  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
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
                      decoration: BoxDecoration(

                        color: Colors.green[300],
                        borderRadius: BorderRadius.only(

                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      height: 200,

                    ),
                    SizedBox(height:30),


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
                          // Header Row
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
                                  Icon(Icons.location_on, size: 18, color: Colors.green.shade900),
                                  SizedBox(width: 4),
                                  Text(
                                    "Green Valley, CA", // later replace with API location
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),

                          SizedBox(height:30 ),

                          // Weather Data Grid
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3,
                              physics: NeverScrollableScrollPhysics(), // prevent scrolling
                              children: [
                                _weatherItem(Icons.thermostat, "Temperature", "25°C"),
                                _weatherItem(Icons.water_drop, "Humidity", "60%"),
                                _weatherItem(Icons.grain, "Rainfall", "5 mm"),
                                _weatherItem(Icons.air, "Wind", "10 km/h"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height:30),
                    Container(
                        height: 250,
                        width:400,
                        margin: EdgeInsets.symmetric(horizontal: 30.0),
                        padding: EdgeInsets.all(50.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.00),

                            color: Colors.green.shade100
                        ),
                        child:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soil Health',style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold
                            ),),
                            Row(
                              children: [

                              ],
                            ),

                            SizedBox(height:20),

                            Expanded(child:
                            Column(
                              children: [
                                _soilHealth("pH Level","6.5"),
                                _soilHealth("Moisture","45%"),
                                _soilHealth("Nitrogen (N)","120 "),
                                _soilHealth("Phosphorus (P)","50"),
                                _soilHealth("Potassium (K)","80")

                              ],
                            )
                            )
                          ],
                        )

                    ),
                    SizedBox(height:30),
                    Container(
                        height: 250,
                        width:400,
                        margin: EdgeInsets.symmetric(horizontal: 30.0),
                        padding: EdgeInsets.all(50.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.00),

                            color: Colors.green.shade100
                        ),
                        child:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Soil Health',style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold
                            ),),
                            Row(
                              children: [

                              ],
                            ),

                            SizedBox(height:20),

                            Expanded(child:
                            Column(
                              children: [
                                _soilHealth("pH Level","6.5"),
                                _soilHealth("Moisture","45%"),
                                _soilHealth("Nitrogen (N)","120 "),
                                _soilHealth("Phosphorus (P)","50"),
                                _soilHealth("Potassium (K)","80")

                              ],
                            )
                            )
                          ],
                        )

                    ),


                  ],

                ),
              ),

              Container(
                  child:
                  Text("hellonigga")
              )
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
        ));
  }}


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
          SizedBox(height:10),
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


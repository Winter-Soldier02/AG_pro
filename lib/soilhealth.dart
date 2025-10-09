import 'package:flutter/material.dart';
import 'dart:math' as math;

class SoilHealthPage extends StatefulWidget {
  @override
  _SoilHealthPageState createState() => _SoilHealthPageState();
}

class _SoilHealthPageState extends State<SoilHealthPage>
    with TickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _showResults = false;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Current soil data (matches your reference)
  Map<String, dynamic> _currentSoilData = {
    'phLevel': 6.5,
    'moisture': 45,
    'nitrogen': 120,
    'phosphorus': 50,
    'potassium': 80,
    'temperature': 22.5,
    'conductivity': 1.2,
    'organicMatter': 3.8,
  };

  // Mock historical data for trends
  List<Map<String, dynamic>> _historicalData = [
    {'date': '2024-01-15', 'ph': 6.2, 'moisture': 40, 'nitrogen': 115},
    {'date': '2024-02-15', 'ph': 6.3, 'moisture': 42, 'nitrogen': 118},
    {'date': '2024-03-15', 'ph': 6.5, 'moisture': 45, 'nitrogen': 120},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _simulateAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _showResults = false;
    });

    _animationController.forward();

    // Simulate sensor data collection
    await Future.delayed(Duration(seconds: 3));

    // Generate some variation in data
    final random = math.Random();
    setState(() {
      _currentSoilData = {
        'phLevel': 6.3 + random.nextDouble() * 0.4, // 6.3 to 6.7
        'moisture': 40 + random.nextInt(20), // 40 to 60
        'nitrogen': 110 + random.nextInt(20), // 110 to 130
        'phosphorus': 45 + random.nextInt(15), // 45 to 60
        'potassium': 75 + random.nextInt(15), // 75 to 90
        'temperature': 20 + random.nextDouble() * 8, // 20 to 28
        'conductivity': 1.0 + random.nextDouble() * 0.5, // 1.0 to 1.5
        'organicMatter': 3.5 + random.nextDouble() * 0.8, // 3.5 to 4.3
      };
      _isAnalyzing = false;
      _showResults = true;
    });

    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0,
        title: Text(
          'Soil Health Monitoring',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _simulateAnalysis,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6BA04A), Color(0xFF5A8F3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _getSoilHealthIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    _getSoilHealthStatus(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Quick Analysis Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _simulateAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  disabledBackgroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isAnalyzing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Analyzing Soil...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Run Soil Analysis',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Current Readings
            Text(
              'Current Readings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),

            // Primary Metrics (pH, Moisture, Temperature)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'pH Level',
                    value: _currentSoilData['phLevel'].toStringAsFixed(1),
                    unit: '',
                    icon: Icons.science,
                    color: _getPhColor(_currentSoilData['phLevel']),
                    progress: (_currentSoilData['phLevel'] - 4) / 6, // pH range 4-10
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Moisture',
                    value: _currentSoilData['moisture'].toString(),
                    unit: '%',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    progress: _currentSoilData['moisture'] / 100,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Temperature',
                    value: _currentSoilData['temperature'].toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: Colors.orange,
                    progress: _currentSoilData['temperature'] / 40,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Conductivity',
                    value: _currentSoilData['conductivity'].toStringAsFixed(1),
                    unit: 'mS/cm',
                    icon: Icons.electric_bolt,
                    color: Colors.purple,
                    progress: _currentSoilData['conductivity'] / 2,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Nutrients Section
            Text(
              'Nutrient Levels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildNutrientBar(
                    'Nitrogen (N)',
                    _currentSoilData['nitrogen'],
                    200,
                    'mg/kg',
                    Colors.green,
                  ),
                  SizedBox(height: 15),
                  _buildNutrientBar(
                    'Phosphorus (P)',
                    _currentSoilData['phosphorus'],
                    100,
                    'mg/kg',
                    Colors.orange,
                  ),
                  SizedBox(height: 15),
                  _buildNutrientBar(
                    'Potassium (K)',
                    _currentSoilData['potassium'],
                    150,
                    'mg/kg',
                    Colors.purple,
                  ),
                  SizedBox(height: 15),
                  _buildNutrientBar(
                    'Organic Matter',
                    _currentSoilData['organicMatter'],
                    5.0,
                    '%',
                    Colors.brown,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Recommendations
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFF6BA04A), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  ..._getRecommendations().map((recommendation) =>
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF6BA04A),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ).toList(),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(
      String name,
      dynamic value,
      double maxValue,
      String unit,
      Color color,
      ) {
    double progress = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value is double ? value.toStringAsFixed(1) : value} $unit',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  IconData _getSoilHealthIcon() {
    double ph = _currentSoilData['phLevel'];
    int moisture = _currentSoilData['moisture'];

    if (ph >= 6.0 && ph <= 7.0 && moisture >= 40 && moisture <= 60) {
      return Icons.eco; // Healthy
    } else if (ph >= 5.5 && ph <= 7.5 && moisture >= 30 && moisture <= 70) {
      return Icons.warning_amber; // Moderate
    } else {
      return Icons.error_outline; // Poor
    }
  }

  String _getSoilHealthStatus() {
    double ph = _currentSoilData['phLevel'];
    int moisture = _currentSoilData['moisture'];

    if (ph >= 6.0 && ph <= 7.0 && moisture >= 40 && moisture <= 60) {
      return 'Excellent soil conditions for most crops';
    } else if (ph >= 5.5 && ph <= 7.5 && moisture >= 30 && moisture <= 70) {
      return 'Good soil health with minor adjustments needed';
    } else {
      return 'Soil requires immediate attention and treatment';
    }
  }

  Color _getPhColor(double ph) {
    if (ph >= 6.0 && ph <= 7.0) {
      return Colors.green; // Optimal
    } else if (ph >= 5.5 && ph <= 7.5) {
      return Colors.orange; // Acceptable
    } else {
      return Colors.red; // Poor
    }
  }

  List<String> _getRecommendations() {
    List<String> recommendations = [];
    double ph = _currentSoilData['phLevel'];
    int moisture = _currentSoilData['moisture'];
    int nitrogen = _currentSoilData['nitrogen'];
    int phosphorus = _currentSoilData['phosphorus'];
    int potassium = _currentSoilData['potassium'];

    // pH recommendations
    if (ph < 6.0) {
      recommendations.add('Add lime to increase soil pH and reduce acidity');
    } else if (ph > 7.5) {
      recommendations.add('Apply sulfur or organic matter to lower soil pH');
    }

    // Moisture recommendations
    if (moisture < 30) {
      recommendations.add('Increase irrigation frequency to improve soil moisture');
    } else if (moisture > 70) {
      recommendations.add('Improve drainage to prevent waterlogging');
    }

    // Nutrient recommendations
    if (nitrogen < 100) {
      recommendations.add('Apply nitrogen-rich fertilizer or compost');
    }
    if (phosphorus < 40) {
      recommendations.add('Add phosphorus fertilizer to boost root development');
    }
    if (potassium < 70) {
      recommendations.add('Apply potassium fertilizer to improve plant disease resistance');
    }

    // Organic matter
    if (_currentSoilData['organicMatter'] < 3.0) {
      recommendations.add('Incorporate organic compost to improve soil structure');
    }

    // Default recommendations if soil is healthy
    if (recommendations.isEmpty) {
      recommendations.addAll([
        'Maintain current fertilization schedule',
        'Continue regular soil testing every 3-6 months',
        'Monitor weather conditions for irrigation adjustments',
      ]);
    }

    return recommendations;
  }}
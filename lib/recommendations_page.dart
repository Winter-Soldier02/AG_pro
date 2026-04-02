import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weatherservices.dart';
import 'api_keys.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final WeatherService _weatherService = WeatherService();

  bool _isWeatherLoading = false;
  bool _isAiLoading = false;

  String _temperature = '--°C';
  String _humidity = '--%';
  String _rainfall = '0%';
  String _windSpeed = '-- km/h';
  String _cityName = 'Mumbai';

  List<Map<String, dynamic>> _recommendations = [];
  String _errorMessage = '';
  String _recommendationSource = 'loading';

  final String _geminiApiKey = ApiKeys.geminiApiKey;

  @override
  void initState() {
    super.initState();
    _loadWeatherAndRecommendations();
  }

  Future<void> _loadWeatherAndRecommendations() async {
    print('\n🔄 ===== STARTING RECOMMENDATION FETCH =====');
    setState(() {
      _isWeatherLoading = true;
      _errorMessage = '';
      _recommendationSource = 'loading';
    });

    try {
      print('📡 Fetching weather data...');
      final weatherData = await _weatherService.fetchWeatherData();
      print('✅ Weather data received');

      setState(() {
        _temperature = '${weatherData['current']['temperature']?.round() ?? '--'}°C';
        _humidity = '${weatherData['hourly']['relative_humidity_2m'][0] ?? '--'}%';
        _rainfall = '${weatherData['hourly']['precipitation_probability'][0] ?? 0}%';
        _windSpeed = '${weatherData['current']['windspeed']?.round() ?? '--'} km/h';
        _cityName = weatherData['city'] ?? 'Mumbai';
      });

      print('🤖 Attempting to fetch AI recommendations...');
      await _generateRecommendations();
    } catch (e) {
      print('❌ Weather fetch failed: $e');
      _setFallbackRecommendations();
    } finally {
      if (mounted) {
        setState(() => _isWeatherLoading = false);
      }
    }
  }


  Future<void> _generateRecommendations() async {
    if (_isAiLoading) return; // Prevent duplicate calls

    setState(() => _isAiLoading = true);

    try {
      print('🌐 Calling Google Gemini API...');
      print('🔑 API Key present: ${_geminiApiKey.isNotEmpty}');


      final response = await http.post(

        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey'
        ),
        headers: {
          'Content-Type': 'application/json',

        },
        body: jsonEncode({

          "contents": [
            {
              "parts": [
                {
                  "text": """Generate 5 farming tips for $_cityName: Temp $_temperature, Humidity $_humidity, Rain $_rainfall, Wind $_windSpeed.

Return ONLY this JSON array (no markdown, no extra text):
[
  {"title":"Water Early Morning","description":"Water crops at 6-8 AM for best absorption.","category":"watering","priority":"high"},
  {"title":"Apply Mulch","description":"Use organic mulch to retain moisture.","category":"protection","priority":"medium"}
]

Use categories: watering, planting, protection, fertilizing, harvesting
Use priority: high, medium, low
Keep descriptions under 15 words."""
                }
              ]
            }
          ],


          "safetySettings": [
            {
              "category": "HARM_CATEGORY_HARASSMENT",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_NONE"
            }
          ]
        }),
      ).timeout(Duration(seconds: 15)); // Kill request if it takes >15s

      print('📥 Gemini Response Status: ${response.statusCode}');


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);



        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No candidates in response');
        }


        final candidate = data['candidates'][0];
        final finishReason = candidate['finishReason'] ?? '';

        if (finishReason == 'MAX_TOKENS' || finishReason == 'LENGTH') {
          print('⚠️ Response was truncated due to length');
          throw Exception('Response truncated - increasing token limit');
        }

        if (finishReason == 'SAFETY') {
          print('⚠️ Response blocked by safety filters');
          throw Exception('Response blocked by safety filters');
        }

        String content = candidate['content']['parts'][0]['text'];


        content = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        print('✅ AI Response received');
        print('📄 Full content length: ${content.length} characters');


        try {
          final recommendationsJson = jsonDecode(content);


          if (recommendationsJson is! List) {
            throw Exception('Response is not an array');
          }

          setState(() {
            _recommendations = List<Map<String, dynamic>>.from(recommendationsJson);
            _recommendationSource = 'ai'; // Mark as AI-generated
          });

          print('🎉 SUCCESS! Using AI-generated recommendations');
          print('📊 Loaded ${_recommendations.length} recommendations');

          // Show success message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('AI recommendations loaded successfully!'),
                  ],
                ),
                backgroundColor: Colors.green.shade700,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (parseError) {
          print('❌ JSON Parse Error: $parseError');
          print('📄 Raw content that failed to parse:');
          print(content);
          throw Exception('Failed to parse JSON: $parseError');
        }

      }

      else if (response.statusCode == 429) {
        print('⚠️ Quota exceeded (429)');
        throw Exception('Quota exceeded');
      }

      else if (response.statusCode == 400) {
        print('❌ Invalid API key or bad request (400)');
        print('Response: ${response.body}');
        throw Exception('Invalid API key');
      }
      else {
        print('❌ API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Gemini error ${response.statusCode}');
      }

    } catch (e) {

      print('❌ AI Generation Failed: $e');
      _setFallbackRecommendations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Using cached recommendations'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAiLoading = false);
      }
    }
  }


  void _setFallbackRecommendations() {
    print('📋 Loading fallback recommendations');


    int temp = 25;
    try {
      temp = int.parse(_temperature.replaceAll('°C', '').replaceAll('--', '25'));
    } catch (e) {
      temp = 25; // Default if parsing fails
    }

    setState(() {
      _recommendations = [
        {
          'title': temp > 30 ? 'Heat Protection' : 'Morning Watering',
          'description': temp > 30
              ? 'High temperatures detected. Provide shade nets and increase watering frequency.'
              : 'Water crops early morning (6-8 AM) for optimal absorption.',
          'category': temp > 30 ? 'protection' : 'watering',
          'priority': 'high',
        },
        {
          'title': 'Mulching Practice',
          'description': 'Apply organic mulch to retain soil moisture and regulate temperature.',
          'category': 'protection',
          'priority': 'medium',
        },
        {
          'title': 'Soil Testing',
          'description': 'Conduct regular soil tests to maintain optimal pH (6-7) and nutrient balance.',
          'category': 'fertilizing',
          'priority': 'high',
        },
        {
          'title': 'Pest Monitoring',
          'description': 'Daily inspection for pests and diseases enables early intervention.',
          'category': 'protection',
          'priority': 'medium',
        },
        {
          'title': 'Crop Rotation Planning',
          'description': 'Plan next season with crop rotation to maintain soil health.',
          'category': 'planting',
          'priority': 'low',
        },
      ];
      _recommendationSource = 'fallback';
    });

    print('✅ Fallback recommendations loaded');
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'watering':
        return Colors.blue;
      case 'planting':
        return Colors.green;
      case 'protection':
        return Colors.orange;
      case 'fertilizing':
        return Colors.purple;
      case 'harvesting':
        return Colors.amber;
      default:
        return Colors.teal;
    }
  }


  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'watering':
        return Icons.water_drop;
      case 'planting':
        return Icons.eco;
      case 'protection':
        return Icons.shield;
      case 'fertilizing':
        return Icons.science;
      case 'harvesting':
        return Icons.agriculture;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header with background image and frost blur
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.green.shade700,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/weather/topcimage1.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Frost blur overlay content
                  Positioned(
                    top: 60,
                    left: 25,
                    right: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title chip with glass effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.tips_and_updates,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Smart Recommendations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Weather summary card with glass effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Current Conditions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            _cityName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _weatherChip(Icons.thermostat, _temperature),
                                      _weatherChip(Icons.water_drop, _humidity),
                                      _weatherChip(Icons.grain, _rainfall),
                                      _weatherChip(Icons.air, _windSpeed),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Powered Tips',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ============================================================
                          // 📊 SOURCE INDICATOR - Shows if using AI or fallback
                          // ============================================================
                          Row(
                            children: [
                              Icon(
                                _recommendationSource == 'ai'
                                    ? Icons.auto_awesome      // Sparkle = AI
                                    : _recommendationSource == 'fallback'
                                    ? Icons.cached           // Cache = Fallback
                                    : Icons.hourglass_empty, // Hourglass = Loading
                                size: 14,
                                color: _recommendationSource == 'ai'
                                    ? Colors.green.shade700
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _recommendationSource == 'ai'
                                    ? 'AI Generated'
                                    : _recommendationSource == 'fallback'
                                    ? 'Cached Tips'
                                    : 'Loading...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _recommendationSource == 'ai'
                                      ? Colors.green.shade700
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Refresh button
                      IconButton(
                        onPressed: _loadWeatherAndRecommendations,
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Based on current weather conditions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ============================================================
                  // 🔄 Loading state
                  // ============================================================
                  if (_isWeatherLoading || _isAiLoading)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          CircularProgressIndicator(
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isAiLoading
                                ? 'Generating AI recommendations...'
                                : 'Loading weather data...',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  // ============================================================
                  // ❌ Error state
                  // ============================================================
                  else if (_errorMessage.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadWeatherAndRecommendations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  // ============================================================
                  // ✅ Success state - Show recommendations
                  // ============================================================
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final recommendation = _recommendations[index];
                        return _buildRecommendationCard(recommendation, index);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏷️ Weather chip widget
  // ============================================================
  Widget _weatherChip(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🃏 Recommendation card widget
  // ============================================================
  Widget _buildRecommendationCard(Map<String, dynamic> recommendation, int index) {
    final category = recommendation['category'] ?? 'general';
    final priority = recommendation['priority'] ?? 'medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // High priority badge
            if (priority == 'high')
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.priority_high,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'HIGH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getCategoryColor(category).withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: _getCategoryColor(category),
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Recommendation content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recommendation['title'] ?? 'Recommendation ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        Text(
                          recommendation['description'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              color: _getCategoryColor(category),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
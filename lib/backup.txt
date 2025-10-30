import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlantHealthPage extends StatefulWidget {
  @override
  _PlantHealthPageState createState() => _PlantHealthPageState();
}

class _PlantHealthPageState extends State<PlantHealthPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResults = false;
  final ImagePicker _picker = ImagePicker();

  // Analysis results
  Map<String, dynamic> _analysisResults = {
    'healthScore': 85,
    'disease': 'Healthy Plant',
    'severity': 'None',
    'confidence': '0%',
    'recommendations': [
      'Continue regular watering schedule',
      'Maintain current fertilization',
      'Monitor for any changes',
      'Ensure adequate sunlight'
    ],
    'nextSteps': [
      'Regular monitoring recommended',
      'Keep soil well-drained',
      'Maintain good air circulation'
    ]
  };

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _showResults = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
    });

    try {
      print('📸 Reading image file...');
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('🌐 Sending request to Hugging Face API...');

      // Correct Hugging Face Inference API endpoint
      final url = Uri.parse(
          'https://api-inference.huggingface.co/models/linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification'
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer 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',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': base64Image,
        }),
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          // Get the top prediction
          final topPrediction = data[0];
          final label = topPrediction['label'] as String;
          final score = topPrediction['score'] as double;
          final confidence = (score * 100).toStringAsFixed(1);

          print('✅ Analysis complete: $label ($confidence%)');

          // Parse the disease name and determine health
          final isHealthy = label.toLowerCase().contains('healthy');
          final diseaseInfo = _parseDiseaseInfo(label, score);

          setState(() {
            _analysisResults = {
              'healthScore': diseaseInfo['healthScore'],
              'disease': diseaseInfo['disease'],
              'severity': diseaseInfo['severity'],
              'confidence': '$confidence%',
              'recommendations': diseaseInfo['recommendations'],
              'nextSteps': diseaseInfo['nextSteps'],
            };
            _showResults = true;
          });
        } else {
          throw Exception('Unexpected API response format');
        }
      } else if (response.statusCode == 503) {
        // Model is loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model is loading. Please try again in 20 seconds.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      // Show mock results as fallback
      setState(() {
        _showResults = true;
        _analysisResults = {
          'healthScore': 75,
          'disease': 'Analysis Error - Using Mock Data',
          'severity': 'Unable to determine',
          'confidence': 'N/A',
          'recommendations': [
            'Please try again with a clearer image',
            'Ensure good lighting when taking photo',
            'Focus on affected leaf areas',
            'Try again in a few moments'
          ],
          'nextSteps': [
            'Retake photo if needed',
            'Check internet connection',
            'Consult local agricultural expert if issue persists'
          ]
        };
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Map<String, dynamic> _parseDiseaseInfo(String label, double score) {
    final confidence = score * 100;
    final isHealthy = label.toLowerCase().contains('healthy');

    // Clean up the label
    String disease = label
        .replaceAll('___', ' - ')
        .replaceAll('__', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    int healthScore;
    String severity;
    List<String> recommendations;
    List<String> nextSteps;

    if (isHealthy) {
      healthScore = (confidence).toInt();
      severity = 'None';
      recommendations = [
        'Continue regular watering schedule',
        'Maintain current fertilization program',
        'Monitor plant regularly for changes',
        'Ensure adequate sunlight exposure'
      ];
      nextSteps = [
        'Keep following current care routine',
        'Regular visual inspections recommended',
        'Maintain optimal growing conditions'
      ];
    } else {
      // Diseased plant
      healthScore = (100 - confidence).toInt();

      if (confidence > 80) {
        severity = 'High';
        recommendations = [
          'Immediate treatment required',
          'Remove severely affected leaves',
          'Apply appropriate fungicide/pesticide',
          'Isolate plant if possible',
          'Improve air circulation',
          'Adjust watering schedule'
        ];
        nextSteps = [
          'Treat immediately',
          'Monitor daily for 7-10 days',
          'Consider consulting an agricultural expert',
          'Document progress with photos'
        ];
      } else if (confidence > 60) {
        severity = 'Moderate';
        recommendations = [
          'Prompt treatment recommended',
          'Remove affected leaves',
          'Apply organic fungicide',
          'Improve plant ventilation',
          'Avoid overhead watering'
        ];
        nextSteps = [
          'Begin treatment within 2-3 days',
          'Monitor closely for one week',
          'Reapply treatment if needed'
        ];
      } else {
        severity = 'Mild';
        recommendations = [
          'Monitor plant closely',
          'Remove affected leaves if any',
          'Improve general plant care',
          'Ensure proper drainage',
          'Maintain optimal watering'
        ];
        nextSteps = [
          'Watch for symptom progression',
          'Take preventive measures',
          'Monitor for 5-7 days'
        ];
      }
    }

    return {
      'healthScore': healthScore,
      'disease': disease,
      'severity': severity,
      'recommendations': recommendations,
      'nextSteps': nextSteps,
    };
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.green.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Color(0xFF6BA04A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        elevation: 0,
        title: Text(
          'Plant Health Assessment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload an image of a plant to get an AI-powered health analysis.',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            SizedBox(height: 30),

            // Upload Area
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Color(0xFF6BA04A),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 50,
                      color: Color(0xFF6BA04A),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Click to upload plant image',
                      style: TextStyle(
                        color: Color(0xFF6BA04A),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'For best results, use a clear image of leaves showing any affected areas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Analyze Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedImage != null && !_isAnalyzing
                    ? _analyzeImage
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6BA04A),
                  disabledBackgroundColor: Colors.grey,
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
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Analyzing...',
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
                    Icon(Icons.biotech, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Analyze Plant Health',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Analysis Report Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: Color(0xFF6BA04A), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Analysis Report',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    _showResults
                        ? 'AI analysis complete with recommendations below.'
                        : 'Your plant health report will appear here.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),

                  if (_showResults) ...[
                    SizedBox(height: 25),

                    // Health Score
                    _buildResultCard(
                      title: 'Overall Health Score',
                      value: '${_analysisResults['healthScore']}/100',
                      icon: Icons.favorite,
                      color: _getHealthColor(_analysisResults['healthScore']),
                    ),

                    SizedBox(height: 15),

                    // Disease Detection
                    _buildResultCard(
                      title: 'Detected Issue',
                      value: _analysisResults['disease'],
                      subtitle:
                      'Severity: ${_analysisResults['severity']} • Confidence: ${_analysisResults['confidence']}',
                      icon: Icons.warning_amber,
                      color: _getSeverityColor(_analysisResults['severity']),
                    ),

                    SizedBox(height: 20),

                    // Recommendations
                    Text(
                      'Recommended Actions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...(_analysisResults['recommendations'] as List)
                        .map<Widget>(
                          (rec) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF6BA04A), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),

                    SizedBox(height: 20),

                    // Next Steps
                    Text(
                      'Next Steps',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...(_analysisResults['nextSteps'] as List)
                        .map<Widget>(
                          (step) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_forward,
                                color: Colors.blue.shade700, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .toList(),
                  ] else ...[
                    SizedBox(height: 40),
                    Center(
                      child: Icon(
                        Icons.eco,
                        size: 60,
                        color: Colors.green.shade300,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Upload a plant image to begin',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'none':
        return Colors.green;
      case 'mild':
        return Colors.blue;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
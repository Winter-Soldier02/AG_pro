import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_keys.dart';


class PlantHealthPage extends StatefulWidget {
  @override
  _PlantHealthPageState createState() => _PlantHealthPageState();
}

class _PlantHealthPageState extends State<PlantHealthPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResults = false;
  final ImagePicker _picker = ImagePicker();

  // Available models - you can switch between these
  String _selectedModel = 'model1'; // Default model

  final Map<String, Map<String, String>> _availableModels = {
    // 'model1': {
    //   'name': 'HealthyPlants (Alternative)',
    //   'endpoint': 'https://api-inference.huggingface.co/models/ombhojane/healthyPlantsModel',
    //   'description': '38 diseases, PlantVillage trained'
    // },
    'model1': {
      'name': 'AG_leaf',
      'endpoint': 'https://api-inference.huggingface.co/models/linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification',
      'description': 'Fast and efficient, 38 classes'
    },
    'model3': {
      'name': 'Crop Diseases ViT',
      'endpoint': 'https://huggingface.co/YuchengShi/LLaVA-v1.5-7B-Plant-Leaf-Diseases-Detection',
      'description': 'Vision Transformer for crops'
    },
    // 'model4': {
    //   'name': 'Plant Detection ViT',
    //   'endpoint': 'https://api-inference.huggingface.co/models/marwaALzaabi/plant-disease-detection-vit',
    //   'description': 'ViT Large model for diseases'
    // },
  };

  Map<String, dynamic> _analysisResults = {
    'healthScore': 85,
    'disease': 'Healthy Plant',
    'severity': 'None',
    'confidence': '0%',
    'recommendations': [],
    'nextSteps': []
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

      final modelEndpoint = _availableModels[_selectedModel]!['endpoint']!;
      print('🌐 Using model: ${_availableModels[_selectedModel]!['name']}');
      print('🔗 Endpoint: $modelEndpoint');

      final url = Uri.parse(modelEndpoint);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFace}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': base64Image,
        }),
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          // Get top 3 predictions
          final predictions = data.take(3).toList();
          final topPrediction = predictions[0];

          final label = topPrediction['label'] as String;
          final score = topPrediction['score'] as double;
          final confidence = (score * 100).toStringAsFixed(1);

          print('✅ Top prediction: $label ($confidence%)');
          print('📊 All predictions:');
          for (var pred in predictions) {
            print('   - ${pred['label']}: ${(pred['score'] * 100).toStringAsFixed(1)}%');
          }

          final diseaseInfo = _parseDiseaseInfo(label, score);

          setState(() {
            _analysisResults = {
              'healthScore': diseaseInfo['healthScore'],
              'disease': diseaseInfo['disease'],
              'severity': diseaseInfo['severity'],
              'confidence': '$confidence%',
              'alternativeDiagnoses': predictions.length > 1
                  ? predictions.skip(1).take(2).map((p) =>
              '${_cleanLabel(p['label'])} (${(p['score'] * 100).toStringAsFixed(1)}%)'
              ).toList()
                  : [],
              'recommendations': diseaseInfo['recommendations'],
              'nextSteps': diseaseInfo['nextSteps'],
            };
            _showResults = true;
          });
        } else {
          throw Exception('Unexpected API response format');
        }
      } else if (response.statusCode == 503) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model is loading. Please wait 20 seconds and try again.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  String _cleanLabel(String label) {
    return label
        .replaceAll('___', ' - ')
        .replaceAll('__', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
  }

  Map<String, dynamic> _parseDiseaseInfo(String label, double score) {
    final confidence = score * 100;
    final isHealthy = label.toLowerCase().contains('healthy');

    String disease = _cleanLabel(label);

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
        'Keep monitoring plant health',
        'Ensure adequate sunlight (6-8 hours daily)'
      ];
      nextSteps = [
        'Weekly visual inspection recommended',
        'Maintain current care routine',
        'Document plant growth progress'
      ];
    } else {
      healthScore = (100 - confidence).toInt();

      if (confidence > 80) {
        severity = 'High';
        recommendations = [
          '⚠️ Immediate action required',
          'Isolate plant from healthy plants',
          'Remove and destroy severely infected leaves',
          'Apply appropriate treatment (fungicide/pesticide)',
          'Improve air circulation around plant',
          'Reduce watering frequency if fungal infection',
          'Clean and disinfect gardening tools'
        ];
        nextSteps = [
          'Begin treatment within 24 hours',
          'Monitor daily for symptom changes',
          'Document with photos for comparison',
          'Consider consulting agricultural expert',
          'Reapply treatment after 7-10 days if needed'
        ];
      } else if (confidence > 60) {
        severity = 'Moderate';
        recommendations = [
          'Prompt treatment recommended',
          'Remove visibly affected leaves',
          'Apply organic or chemical treatment as appropriate',
          'Improve plant spacing for better airflow',
          'Adjust watering - avoid overhead irrigation',
          'Apply mulch to prevent soil splash'
        ];
        nextSteps = [
          'Start treatment within 2-3 days',
          'Monitor every 2-3 days for one week',
          'Take progress photos',
          'Repeat treatment if symptoms worsen'
        ];
      } else {
        severity = 'Mild';
        recommendations = [
          'Monitor plant condition closely',
          'Remove any symptomatic leaves',
          'Ensure proper drainage',
          'Optimize watering schedule',
          'Consider preventive organic treatments',
          'Check for pest presence'
        ];
        nextSteps = [
          'Observe for symptom progression',
          'Check plant every 3-4 days',
          'Improve general plant care',
          'Apply treatment only if symptoms worsen'
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

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Model',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Different models may provide varying results',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            SizedBox(height: 20),
            ..._availableModels.entries.map((entry) {
              return RadioListTile<String>(
                value: entry.key,
                groupValue: _selectedModel,
                activeColor: Color(0xFF6BA04A),
                title: Text(
                  entry.value['name']!,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  entry.value['description']!,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedModel = value!;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Model changed to: ${entry.value['name']}'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: Colors.black),
            tooltip: 'Change AI Model',
            onPressed: _showModelSelector,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upload an image of a plant to get an AI-powered health analysis.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Model selector chip
            GestureDetector(
              onTap: _showModelSelector,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF6BA04A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, color: Color(0xFF6BA04A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Model: ${_availableModels[_selectedModel]!['name']}',
                      style: TextStyle(
                        color: Color(0xFF6BA04A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_drop_down, color: Color(0xFF6BA04A), size: 20),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

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
                        'Focus on affected leaves for best results',
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
                      title: 'Primary Diagnosis',
                      value: _analysisResults['disease'],
                      subtitle:
                      'Severity: ${_analysisResults['severity']} • Confidence: ${_analysisResults['confidence']}',
                      icon: Icons.coronavirus,
                      color: _getSeverityColor(_analysisResults['severity']),
                    ),

                    // Alternative diagnoses
                    if (_analysisResults['alternativeDiagnoses'] != null &&
                        (_analysisResults['alternativeDiagnoses'] as List).isNotEmpty) ...[
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                                SizedBox(width: 8),
                                Text(
                                  'Alternative Possibilities',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            ...(_analysisResults['alternativeDiagnoses'] as List).map((alt) =>
                                Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $alt',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                  ),
                                ),
                            ).toList(),
                          ],
                        ),
                      ),
                    ],

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
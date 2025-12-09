import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_ai/features/ai_predictions/models/disease_prediction.dart';
import 'package:crop_ai/features/ai_predictions/providers/disease_provider.dart';

class DiseaseDetectionScreen extends ConsumerStatefulWidget {
  final String farmId;

  const DiseaseDetectionScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  ConsumerState<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState
    extends ConsumerState<DiseaseDetectionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _selectedImage = bytes);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _runPrediction() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final input = DiseaseDetectionInput(
        imageBytes: _selectedImage!,
        photoPath: 'disease_${DateTime.now().millisecondsSinceEpoch}.jpg',
        farmId: widget.farmId,
      );

      await ref.read(runDiseaseDetectionProvider(input).future);
      
      if (mounted) {
        _showSuccess('Disease detection completed!');
        setState(() => _selectedImage = null);
      }
    } catch (e) {
      _showError('Error running prediction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmPredictions = ref.watch(farmDiseasePredictionsProvider(widget.farmId));
    final farmStats = ref.watch(farmDiseaseStatsProvider(widget.farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Camera preview section
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedImage != null
                ? Image.memory(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    height: 300,
                  )
                : Container(
                    height: 300,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            gap: 12,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runPrediction,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: _isLoading ? const Text('Analyzing...') : const Text('Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistics section
          farmStats.when(
            data: (stats) => _buildStatsSection(stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error: $err'),
          ),
          const SizedBox(height: 32),

          // Recent predictions section
          Text(
            'Recent Predictions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          farmPredictions.when(
            data: (predictions) {
              if (predictions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No predictions yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final pred = predictions[index];
                  return _buildPredictionCard(pred);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total',
                  '${stats['total_predictions'] ?? 0}',
                ),
                _buildStatItem(
                  'Critical',
                  '${stats['critical_count'] ?? 0}',
                  color: Colors.red,
                ),
                _buildStatItem(
                  'High',
                  '${stats['high_count'] ?? 0}',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  'Medium',
                  '${stats['medium_count'] ?? 0}',
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats['most_common_disease'] != null)
              Text(
                'Most Common: ${stats['most_common_disease']}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),
            Text(
              'Avg Confidence: ${((stats['average_confidence'] as double?) ?? 0).toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(DiseasePrediction prediction) {
    final severityColor = _getSeverityColor(prediction.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.diseaseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.2),
                    border: Border.all(color: severityColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prediction.severity,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (prediction.treatments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Treatments:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prediction.treatments.map((treatment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              treatment,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Detected: ${prediction.detectionTime.toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.amber;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

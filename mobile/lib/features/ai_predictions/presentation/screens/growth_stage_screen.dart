import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_ai/features/ai_predictions/models/growth_stage_prediction.dart';
import 'package:crop_ai/features/ai_predictions/providers/growth_stage_provider.dart';

class GrowthStageScreen extends ConsumerStatefulWidget {
  final String farmId;

  const GrowthStageScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  ConsumerState<GrowthStageScreen> createState() => _GrowthStageScreenState();
}

class _GrowthStageScreenState extends ConsumerState<GrowthStageScreen> {
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
      final input = GrowthStagePredictionInput(
        imageBytes: _selectedImage!,
        photoPath: 'growth_${DateTime.now().millisecondsSinceEpoch}.jpg',
        farmId: widget.farmId,
      );

      await ref.read(runGrowthStagePredictionProvider(input).future);

      if (mounted) {
        _showSuccess('Growth stage prediction completed!');
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
    final currentStage = ref.watch(currentGrowthStageProvider(widget.farmId));
    final stageInfo = ref.watch(currentStageInfoProvider(widget.farmId));
    final farmStats = ref.watch(farmGrowthStageStatsProvider(widget.farmId));
    final harvestDate = ref.watch(estimatedHarvestDateProvider(widget.farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Stage Monitoring'),
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
                  label: _isLoading
                      ? const Text('Analyzing...')
                      : const Text('Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Current stage info
          stageInfo.when(
            data: (info) {
              if (info == null) {
                return const SizedBox.shrink();
              }
              return _buildCurrentStageCard(info);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Harvest date estimate
          harvestDate.when(
            data: (date) {
              if (date == null) {
                return const SizedBox.shrink();
              }
              return _buildHarvestDateCard(date);
            },
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Statistics section
          farmStats.when(
            data: (stats) => _buildStatsSection(stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error: $err'),
          ),
          const SizedBox(height: 24),

          // Recent predictions section
          Text(
            'Observation History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final predictions = ref.watch(
                farmGrowthStagePredictionsProvider(widget.farmId),
              );

              return predictions.when(
                data: (predictions) {
                  if (predictions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No observations yet',
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
                      return _buildObservationCard(pred, index);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Text('Error: $err'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStageCard(Map<String, dynamic> info) {
    final stageName = info['current_stage'] as String;
    final stage = GrowthStage.values.firstWhere(
      (s) => s.name == stageName,
      orElse: () => GrowthStage.seedling,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Stage',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stage.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  stage.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressIndicator(
              (info['days_in_current'] as double).toInt(),
              stage.weekStart * 7,
              stage.weekEnd * 7,
              'Days in Stage',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStageStat(
                  'Days in Stage',
                  '${(info['days_in_current'] as double).toInt()}',
                ),
                _buildStageStat(
                  'Est. Days to Next',
                  '${(info['estimated_days_to_next'] as double).toInt()}',
                ),
                _buildStageStat(
                  'Total Days',
                  '${(info['total_days_since_planting'] as double).toInt()}',
                ),
              ],
            ),
            if ((info['recommendations'] as List).isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...(info['recommendations'] as List<String>).map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestDateCard(DateTime harvestDate) {
    final daysUntil = harvestDate.difference(DateTime.now()).inDays;

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Harvest',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${harvestDate.day}/${harvestDate.month}/${harvestDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$daysUntil',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
                const Text(
                  'days remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
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
            _buildStatRow(
              'Total Observations',
              '${stats['total_observations']}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Avg Days/Stage',
              '${(stats['average_days_per_stage'] as double).toStringAsFixed(1)}',
            ),
            if (stats['earliest_stage'] != null) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                'First Stage',
                '${stats['earliest_stage']}',
              ),
            ],
            if (stats['latest_stage'] != null) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                'Latest Stage',
                '${stats['latest_stage']}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    int current,
    int min,
    int max,
    String label,
  ) {
    final progress = (current - min) / (max - min);
    final safeProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: safeProgress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.green.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildObservationCard(GrowthStagePrediction prediction, int index) {
    final stage = prediction.currentStage;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              stage.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${prediction.daysInStage.toInt()} days in stage',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              '${prediction.daysToNextStage.toInt()}d to next',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

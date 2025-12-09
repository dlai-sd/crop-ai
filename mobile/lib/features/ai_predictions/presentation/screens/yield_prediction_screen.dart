import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/ai_predictions/models/yield_prediction.dart';
import 'package:crop_ai/features/ai_predictions/providers/yield_provider.dart';

class YieldPredictionScreen extends ConsumerStatefulWidget {
  final String farmId;

  const YieldPredictionScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  ConsumerState<YieldPredictionScreen> createState() =>
      _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  final List<TextEditingController> _featureControllers = [];
  final List<String> _featureLabels = [
    'Temperature (°C)',
    'Rainfall (mm)',
    'Humidity (%)',
    'Soil pH',
    'Nitrogen (kg/ha)',
    'Phosphorus (kg/ha)',
    'Potassium (kg/ha)',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _featureLabels.length; i++) {
      _featureControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _runPrediction() async {
    // Validate all fields filled
    for (var controller in _featureControllers) {
      if (controller.text.isEmpty) {
        _showError('Please fill all fields');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final features = _featureControllers
          .map((c) => double.parse(c.text))
          .toList();

      final input = YieldPredictionInput(
        features: features,
        farmId: widget.farmId,
      );

      await ref.read(runYieldPredictionProvider(input).future);

      if (mounted) {
        _showSuccess('Yield prediction completed!');
        // Clear form
        for (var controller in _featureControllers) {
          controller.clear();
        }
      }
    } catch (e) {
      _showError('Error: $e');
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
    final currentPrediction = ref.watch(
      currentYieldPredictionProvider(widget.farmId),
    );
    final farmStats = ref.watch(farmYieldStatsProvider(widget.farmId));
    final yieldTrend = ref.watch(yieldTrendProvider(widget.farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yield Prediction'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Conditions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_featureLabels.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _featureControllers[index],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: _featureLabels[index],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                          : const Icon(Icons.calculate),
                      label: _isLoading
                          ? const Text('Predicting...')
                          : const Text('Predict Yield'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Current prediction
          currentPrediction.when(
            data: (prediction) {
              if (prediction == null) {
                return const SizedBox.shrink();
              }
              return _buildPredictionCard(prediction);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Trend section
          yieldTrend.when(
            data: (trend) {
              if (trend['trend'] == 'insufficient_data') {
                return const SizedBox.shrink();
              }
              return _buildTrendCard(trend);
            },
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),

          // Statistics
          farmStats.when(
            data: (stats) => _buildStatsSection(stats),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Text('Error: $err'),
          ),
          const SizedBox(height: 24),

          // History section
          Text(
            'Prediction History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final farmPredictions = ref.watch(
                farmYieldPredictionsProvider(widget.farmId),
              );

              return farmPredictions.when(
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
                      return _buildHistoryCard(pred, index);
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

  Widget _buildPredictionCard(YieldPrediction prediction) {
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
                Text(
                  'Current Prediction',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: prediction.isReliable
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prediction.isReliable ? 'Reliable' : 'Low Confidence',
                    style: TextStyle(
                      color: prediction.isReliable
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildYieldStat(
                  'Estimated',
                  '${prediction.estimatedYield.toStringAsFixed(0)} kg/ha',
                ),
                _buildYieldStat(
                  'Lower Bound',
                  '${prediction.lowerBound.toStringAsFixed(0)}',
                  color: Colors.red.shade500,
                ),
                _buildYieldStat(
                  'Upper Bound',
                  '${prediction.upperBound.toStringAsFixed(0)}',
                  color: Colors.green.shade500,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: prediction.confidence,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  prediction.isReliable
                      ? Colors.green.shade400
                      : Colors.orange.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (prediction.riskFactors.isNotEmpty)
              _buildFactorsList('Risk Factors', prediction.riskFactors,
                  Colors.red.shade100),
            if (prediction.opportunities.isNotEmpty)
              _buildFactorsList('Opportunities', prediction.opportunities,
                  Colors.green.shade100),
          ],
        ),
      ),
    );
  }

  Widget _buildYieldStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendCard(Map<String, dynamic> trend) {
    final isIncreasing = trend['trend'] == 'increasing';
    final changePercent = (trend['change_percent'] as double).abs();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trend',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isIncreasing ? Icons.trending_up : Icons.trending_down,
                      color: isIncreasing ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isIncreasing ? 'Increasing' : 'Decreasing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncreasing ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isIncreasing ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'vs Previous',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              'Total Predictions',
              '${stats['total_predictions']}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Average Yield',
              '${(stats['average_yield'] as double).toStringAsFixed(0)} kg/ha',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Min/Max Yield',
              '${(stats['min_yield'] as double).toStringAsFixed(0)} - ${(stats['max_yield'] as double).toStringAsFixed(0)}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Reliable Predictions',
              '${stats['reliable_predictions']} / ${stats['total_predictions']}',
            ),
          ],
        ),
      ),
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

  Widget _buildFactorsList(String title, List<String> factors, Color bgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...factors.map((factor) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                factor,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHistoryCard(YieldPrediction prediction, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prediction ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${prediction.estimatedYield.toStringAsFixed(0)} kg/ha',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: prediction.isReliable
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: prediction.isReliable
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

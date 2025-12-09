import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/analytics/providers/analytics_provider.dart';
import 'package:crop_ai/features/analytics/presentation/widgets/chart_widgets.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  final String farmId;

  const AnalyticsDashboardScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider(farmId));
    final keyMetrics = ref.watch(keyMetricsProvider(farmId));
    final diseaseTrend = ref.watch(diseaseTrendProvider(farmId));
    final yieldTrend = ref.watch(yieldTrendChartProvider(farmId));
    final diseaseSeverity = ref.watch(diseaseSeverityProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Analytics'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSummaryProvider);
          ref.invalidate(keyMetricsProvider);
          ref.invalidate(diseaseTrendProvider);
          ref.invalidate(yieldTrendChartProvider);
          ref.invalidate(diseaseSeverityProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Key metrics
            keyMetrics.when(
              data: (metrics) => _buildMetricsRow(metrics),
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Summary cards
            summary.when(
              data: (s) => _buildSummaryCards(s),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Disease severity
            diseaseSeverity.when(
              data: (data) => _buildSeverityCard(data),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Trends section
            Text(
              'Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            DiseaseChartWidget(farmId: farmId),
            const SizedBox(height: 12),
            YieldChartWidget(farmId: farmId),
            const SizedBox(height: 12),
            SeverityDistributionChart(farmId: farmId),
            const SizedBox(height: 12),
            CommonDiseasesChart(farmId: farmId),
            const SizedBox(height: 12),
            ConfidenceTrendChart(farmId: farmId),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> metrics) {
    return Row(
      children: [
        _buildMetricTile(
          '${metrics['totalDiseases']}',
          'Detections',
          Colors.red.shade100,
          Colors.red.shade700,
        ),
        const SizedBox(width: 12),
        _buildMetricTile(
          '${metrics['avgYield']} kg/ha',
          'Avg Yield',
          Colors.green.shade100,
          Colors.green.shade700,
        ),
        const SizedBox(width: 12),
        _buildMetricTile(
          '${metrics['daysToHarvest']}d',
          'To Harvest',
          Colors.amber.shade100,
          Colors.amber.shade700,
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(dynamic s) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Stage',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.currentStage,
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
                    const Text(
                      'Harvest',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.daysToHarvest}d',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityCard(List<dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disease Severity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...data.map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${d.color?.replaceFirst('#', '')}')),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(d.label),
                    const Spacer(),
                    Text(
                      '${d.value.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(String title, int dataPoints) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dataPoints data points',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Icon(Icons.trending_up, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

class FarmCard extends StatelessWidget {
  final Farm farm;
  const FarmCard({required this.farm, Key? key}) : super(key: key);

  Color _getHealthColor() {
    switch (farm.healthStatus) {
      case 'healthy': return Colors.green;
      case 'warning': return Colors.orange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getHealthIcon() {
    switch (farm.healthStatus) {
      case 'healthy': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'critical': return Icons.error;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getHealthColor();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(farm.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text('${farm.areaHectares} hectares • ${farm.cropType}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(_getHealthIcon(), color: color, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Soil Moisture', style: Theme.of(context).textTheme.labelSmall),
                      Text('${farm.soilMoisture.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature', style: Theme.of(context).textTheme.labelSmall),
                      Text('${farm.temperature.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.bodyMedium),
                    ],
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

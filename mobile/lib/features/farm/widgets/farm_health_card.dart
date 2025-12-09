import 'package:flutter/material.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

class FarmHealthCard extends StatelessWidget {
  final Farm farm;
  const FarmHealthCard({required this.farm, Key? key}) : super(key: key);

  Color _getHealthColor() {
    switch (farm.healthStatus) {
      case 'healthy': return Colors.green;
      case 'warning': return Colors.orange;
      case 'critical': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getHealthMessage() {
    switch (farm.healthStatus) {
      case 'healthy': return 'Farm is in excellent condition';
      case 'warning': return 'Farm needs attention';
      case 'critical': return 'Farm requires immediate action';
      default: return 'Unknown status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getHealthColor();
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.favorite, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Status', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(_getHealthMessage(), style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

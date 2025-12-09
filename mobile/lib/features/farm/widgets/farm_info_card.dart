import 'package:flutter/material.dart';
import 'package:crop_ai/features/farm/models/farm.dart';

class FarmInfoCard extends StatelessWidget {
  final Farm farm;
  const FarmInfoCard({required this.farm, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Location', value: '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Area', value: '${farm.areaHectares} hectares'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Crop Type', value: farm.cropType),
            const SizedBox(height: 12),
            _InfoRow(label: 'Planting Date', value: '${farm.plantingDate.day}/${farm.plantingDate.month}/${farm.plantingDate.year}'),
            if (farm.expectedHarvestDate != null) ...[
              const SizedBox(height: 12),
              _InfoRow(label: 'Expected Harvest', value: '${farm.expectedHarvestDate!.day}/${farm.expectedHarvestDate!.month}/${farm.expectedHarvestDate!.year}'),
            ],
            const SizedBox(height: 12),
            _InfoRow(label: 'Soil Moisture', value: '${farm.soilMoisture.toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            _InfoRow(label: 'Temperature', value: '${farm.temperature.toStringAsFixed(1)}°C'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

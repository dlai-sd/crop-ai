import 'package:flutter/material.dart';
import 'package:crop_ai/features/recommendations/models/recommendation.dart';

class TreatmentDetailCard extends StatelessWidget {
  final TreatmentRecommendation treatment;
  final VoidCallback? onApply;

  const TreatmentDetailCard({
    Key? key,
    required this.treatment,
    this.onApply,
  }) : super(key: key);

  Color _getSeverityColor(RecommendationSeverity severity) {
    switch (severity) {
      case RecommendationSeverity.critical:
        return Colors.red;
      case RecommendationSeverity.high:
        return Colors.orange;
      case RecommendationSeverity.medium:
        return Colors.amber;
      case RecommendationSeverity.low:
        return Colors.blue;
      case RecommendationSeverity.info:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        leading: Icon(Icons.medical_services, color: _getSeverityColor(treatment.severity)),
        title: Text(treatment.treatmentName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(treatment.diseaseName),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text(treatment.description),
                SizedBox(height: 16),

                // Steps
                Text('Application Steps', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: treatment.steps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: _getSeverityColor(treatment.severity),
                            child: Text('${index + 1}',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text(treatment.steps[index])),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),

                // Specifications
                Container(
                  padding: EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SpecRow('Pesticide', treatment.pesticide),
                      _SpecRow('Dosage', '${treatment.dosage} ${treatment.unit}'),
                      _SpecRow('Reapply Every', '${treatment.daysToReapply} days'),
                      _SpecRow('Expected Effectiveness',
                          '${(treatment.expectedEffectiveness * 100).toStringAsFixed(0)}%'),
                      _SpecRow('Cost (per hectare)', 'Rs. ${treatment.cost.toStringAsFixed(0)}'),
                      _SpecRow('Supplier', treatment.supplier),
                      _SpecRow('Organic', treatment.isOrganic ? 'Yes' : 'No'),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onApply,
                      icon: Icon(Icons.check),
                      label: Text('Mark Applied'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showContactSupplier(context),
                      icon: Icon(Icons.phone),
                      label: Text('Contact Supplier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupplier(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact: ${treatment.supplier}')),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class YieldOptimizationCard extends StatelessWidget {
  final YieldOptimizationRecommendation recommendation;
  final VoidCallback? onApply;

  const YieldOptimizationCard({
    Key? key,
    required this.recommendation,
    this.onApply,
  }) : super(key: key);

  Color _getSeverityColor(RecommendationSeverity severity) {
    switch (severity) {
      case RecommendationSeverity.critical:
        return Colors.red;
      case RecommendationSeverity.high:
        return Colors.orange;
      case RecommendationSeverity.medium:
        return Colors.amber;
      case RecommendationSeverity.low:
        return Colors.blue;
      case RecommendationSeverity.info:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        leading: Icon(Icons.trending_up, color: _getSeverityColor(recommendation.severity)),
        title: Text(recommendation.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(recommendation.type),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text(recommendation.description),
                SizedBox(height: 16),

                Text('Action Item', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text(recommendation.actionItem),
                SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SpecRow('Expected Yield Increase',
                          '${recommendation.expectedYieldIncrease.toStringAsFixed(0)} kg/ha'),
                      _SpecRow('Confidence',
                          '${(recommendation.confidence * 100).toStringAsFixed(0)}%'),
                      _SpecRow('Cost (per hectare)',
                          'Rs. ${recommendation.cost.toStringAsFixed(0)}'),
                      _SpecRow('Timing Window', recommendation.timingWindow),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: onApply,
                  icon: Icon(Icons.check),
                  label: Text('Mark Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RiskAlertCard extends StatelessWidget {
  final RiskAlert alert;
  final VoidCallback? onDismiss;

  const RiskAlertCard({
    Key? key,
    required this.alert,
    this.onDismiss,
  }) : super(key: key);

  Color _getSeverityColor(RecommendationSeverity severity) {
    switch (severity) {
      case RecommendationSeverity.critical:
        return Colors.red;
      case RecommendationSeverity.high:
        return Colors.orange;
      case RecommendationSeverity.medium:
        return Colors.amber;
      case RecommendationSeverity.low:
        return Colors.blue;
      case RecommendationSeverity.info:
        return Colors.green;
    }
  }

  IconData _getAlertIcon(String riskType) {
    switch (riskType) {
      case 'disease':
        return Icons.bug_report;
      case 'pest':
        return Icons.pest_control;
      case 'weather':
        return Icons.cloud_queue;
      case 'soil':
        return Icons.public;
      case 'water':
        return Icons.water_drop;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      color: _getSeverityColor(alert.severity).withOpacity(0.1),
      child: ExpansionTile(
        leading: Icon(_getAlertIcon(alert.riskType),
            color: _getSeverityColor(alert.severity)),
        title: Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Risk Score: ${(alert.riskScore * 100).toStringAsFixed(0)}%'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text(alert.description),
                SizedBox(height: 16),

                Text('Mitigation Steps', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                Text(alert.mitigation),
                SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SpecRow('Expected Impact',
                          alert.expectedImpactDate.difference(DateTime.now()).inDays.toString() + ' days'),
                      _SpecRow('Alert Type', alert.riskType),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close),
                  label: Text('Dismiss Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

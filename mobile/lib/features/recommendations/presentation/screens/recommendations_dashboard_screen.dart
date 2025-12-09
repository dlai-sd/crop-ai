import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crop_ai/features/recommendations/models/recommendation.dart';
import 'package:crop_ai/features/recommendations/providers/recommendations_provider.dart';
import 'package:crop_ai/features/recommendations/presentation/widgets/recommendation_cards.dart';

class RecommendationsDashboardScreen extends ConsumerStatefulWidget {
  final String farmId;

  const RecommendationsDashboardScreen({Key? key, required this.farmId}) : super(key: key);

  @override
  ConsumerState<RecommendationsDashboardScreen> createState() =>
      _RecommendationsDashboardScreenState();
}

class _RecommendationsDashboardScreenState extends ConsumerState<RecommendationsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.medical_services), text: 'Treatments'),
            Tab(icon: Icon(Icons.trending_up), text: 'Yield'),
            Tab(icon: Icon(Icons.warning), text: 'Risks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TreatmentRecommendationsTab(farmId: widget.farmId),
          _YieldRecommendationsTab(farmId: widget.farmId),
          _RiskAlertsTab(farmId: widget.farmId),
        ],
      ),
    );
  }
}

class _TreatmentRecommendationsTab extends ConsumerWidget {
  final String farmId;

  const _TreatmentRecommendationsTab({Key? key, required this.farmId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(treatmentRecommendationsProvider(farmId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(treatmentRecommendationsProvider(farmId));
      },
      child: treatmentsAsync.when(
        data: (treatments) {
          if (treatments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.health_and_safety, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No disease detected', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Your crops look healthy!'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final treatment = treatments[index];
              return TreatmentDetailCard(
                treatment: treatment,
                onApply: () => _showAppliedSnackbar(context, treatment.treatmentName),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showAppliedSnackbar(BuildContext context, String treatmentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$treatmentName marked as applied'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }
}

class _YieldRecommendationsTab extends ConsumerWidget {
  final String farmId;

  const _YieldRecommendationsTab({Key? key, required this.farmId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yieldAsync = ref.watch(yieldRecommendationsProvider(farmId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(yieldRecommendationsProvider(farmId));
      },
      child: yieldAsync.when(
        data: (recommendations) {
          if (recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No recommendations', style: Theme.of(context).textTheme.headlineSmall),
                  Text('Current management is optimal'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return YieldOptimizationCard(
                recommendation: rec,
                onApply: () => _showCompletedSnackbar(context, rec.title),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showCompletedSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title marked as completed')),
    );
  }
}

class _RiskAlertsTab extends ConsumerWidget {
  final String farmId;

  const _RiskAlertsTab({Key? key, required this.farmId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(riskAlertsProvider(farmId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(riskAlertsProvider(farmId));
      },
      child: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No active risks', style: Theme.of(context).textTheme.headlineSmall),
                  Text('All systems normal'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return RiskAlertCard(
                alert: alert,
                onDismiss: () => _showDismissSnackbar(context, alert.title),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showDismissSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title dismissed')),
    );
  }
}

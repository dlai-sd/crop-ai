import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/farm_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/farm_card.dart';
import '../widgets/sync_status_widget.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmListAsync = ref.watch(farmListProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        elevation: 2,
        actions: [
          // Sync status indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: SyncStatusWidget(
              iconSize: 24,
              showLabel: false,
            ),
          ),
          // Refresh button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: syncStatus == SyncStatus.syncing
                  ? null
                  : () => _performSync(context, ref),
              tooltip: 'Refresh farms',
            ),
          ),
          // Menu button
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context, ref),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'add_farm',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Add Farm'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: farmListAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _buildErrorWidget(
          context,
          ref,
          error.toString(),
        ),
        data: (farms) => farms.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildFarmList(context, ref, farms),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddFarm(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFarmList(BuildContext context, WidgetRef ref, List<Farm> farms) =>
      RefreshIndicator(
        onRefresh: () async => _performSync(context, ref),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: farms.length,
          itemBuilder: (context, index) => FarmCard(
            farm: farms[index],
            onTap: () => _navigateToFarmDetails(context, farms[index]),
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Farms Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first farm',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddFarm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Farm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _performSync(context, ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Sync Data'),
            ),
          ],
        ),
      );

  Widget _buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    String error,
  ) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Farms',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Using cached data (offline mode). Tap retry to sync.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _performSync(context, ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    final syncNotifier = ref.read(syncStatusProvider.notifier);
    await syncNotifier.performSync();
    ref.refresh(farmListProvider);
  }

  void _navigateToFarmDetails(BuildContext context, Farm farm) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${farm.name} details...'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Replace with actual navigation to FarmDetailsScreen
  }

  void _navigateToAddFarm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Farm screen coming next...'),
        duration: Duration(seconds: 1),
      ),
    );
    // TODO: Replace with actual navigation to AddFarmScreen
  }

  void _handleMenuAction(String value, BuildContext context, WidgetRef ref) {
    switch (value) {
      case 'add_farm':
        _navigateToAddFarm(context);
        break;
      case 'settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings screen coming next...'),
            duration: Duration(seconds: 1),
          ),
        );
        break;
    }
  }
}

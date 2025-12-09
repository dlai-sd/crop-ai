import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/features/farm/providers/farm_provider.dart';
import 'package:crop_ai/features/farm/widgets/farm_health_card.dart';
import 'package:crop_ai/features/farm/widgets/farm_info_card.dart';

class FarmDetailScreen extends ConsumerWidget {
  final String farmId;
  const FarmDetailScreen({required this.farmId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmByIdProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: farmAsync.when(
        data: (farm) {
          if (farm == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.not_found, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), const Text('Farm not found')],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('${farm.areaHectares} hectares • ${farm.cropType}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FarmHealthCard(farm: farm),
                const SizedBox(height: 16),
                FarmInfoCard(farm: farm),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.edit), label: const Text('Edit'), onPressed: () {})),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.delete), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]), onPressed: () {})),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

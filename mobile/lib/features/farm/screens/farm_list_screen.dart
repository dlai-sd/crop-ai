import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/features/farm/providers/farm_provider.dart';
import 'package:crop_ai/features/farm/widgets/farm_card.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Farms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(farmListNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(farmListNotifierProvider.notifier).refresh();
        },
        child: farmsAsync.when(
          data: (farms) {
            if (farms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.landscape, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No farms yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () {}, child: const Text('Add your first farm')),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: farms.length,
              itemBuilder: (context, index) {
                final farm = farms[index];
                return GestureDetector(
                  onTap: () => context.go('/farm/${farm.id}'),
                  child: FarmCard(farm: farm),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error loading farms', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.read(farmListNotifierProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add Farm',
        child: const Icon(Icons.add),
      ),
    );
  }
}

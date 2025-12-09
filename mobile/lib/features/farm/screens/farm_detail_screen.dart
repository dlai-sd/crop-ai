import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/core/localization/app_localizations.dart';
import 'package:crop_ai/features/farm/providers/farm_provider.dart';
import 'package:crop_ai/features/farm/widgets/farm_health_card.dart';
import 'package:crop_ai/features/farm/widgets/farm_info_card.dart';
import 'package:crop_ai/features/weather/providers/weather_provider.dart';
import 'package:crop_ai/features/weather/widgets/weather_display_card.dart';

class FarmDetailScreen extends ConsumerWidget {
  final String farmId;
  const FarmDetailScreen({required this.farmId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmByIdProvider(farmId));
    final weatherAsync = ref.watch(weatherProvider(farmId));
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n?.farmDetails ?? 'Farm Details'),
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
                Text('${farm.areaHectares} ${i18n?.farmHectares ?? 'hectares'} • ${farm.cropType}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                FarmHealthCard(farm: farm),
                const SizedBox(height: 16),
                
                // Weather widget
                weatherAsync.when(
                  data: (weather) {
                    return Column(
                      children: [
                        WeatherDisplayCard(weather: weather),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: SizedBox(
                        height: 200,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(i18n?.loading ?? 'Loading...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i18n?.weatherTitle ?? 'Weather', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('${i18n?.error ?? 'Error'}: ${err.toString()}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                FarmInfoCard(farm: farm),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.edit), label: Text(i18n?.edit ?? 'Edit'), onPressed: () {})),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.delete), label: Text(i18n?.delete ?? 'Delete'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]), onPressed: () {})),
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

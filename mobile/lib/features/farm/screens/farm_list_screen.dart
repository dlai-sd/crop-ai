import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crop_ai/features/farm/providers/farm_provider.dart';
import 'package:crop_ai/features/farm/widgets/farm_card.dart';
import 'package:crop_ai/core/localization/app_localizations.dart';
import 'package:crop_ai/core/localization/locale_provider.dart';

class FarmListScreen extends ConsumerWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmListNotifierProvider);
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n?.farmTitle ?? 'My Farms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguagePicker(context, ref),
          ),
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
                    Text(i18n?.farmEmpty ?? 'No farms yet', 
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/farm/add'),
                      child: Text(i18n?.farmAddFirst ?? 'Add your first farm'),
                    ),
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
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(i18n?.loading ?? 'Loading...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(i18n?.error ?? 'Error', 
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => 
                    ref.read(farmListNotifierProvider.notifier).refresh(),
                  child: Text(i18n?.retry ?? 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farm/add'),
        tooltip: i18n?.farmAddFarm ?? 'Add Farm',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Select Language',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView(
                children: LocaleNotifier.supportedLanguages.entries
                    .map((entry) {
                  return ListTile(
                    title: Text(entry.value),
                    onTap: () {
                      ref.read(localeProvider.notifier)
                          .setLocale(Locale(entry.key));
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

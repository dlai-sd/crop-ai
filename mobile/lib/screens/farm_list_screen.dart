import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../generated_l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/localization_provider.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class FarmListScreen extends ConsumerStatefulWidget {
  const FarmListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends ConsumerState<FarmListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.refresh(farmsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final farmsAsync = ref.watch(farmsProvider);
    final networkState = ref.watch(networkStatusProvider);
    final syncState = ref.watch(syncProvider);
    final l10n = AppLocalizations.of(context)!;
    final appLanguage = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri-Pulse'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Language selector
          PopupMenuButton<AppLanguage>(
            onSelected: (language) {
              ref.read(appLanguageProvider.notifier).state = language;
            },
            itemBuilder: (BuildContext context) {
              return AppLanguage.values.map((language) {
                return PopupMenuItem<AppLanguage>(
                  value: language,
                  child: Row(
                    children: [
                      Checkbox(
                        value: appLanguage == language,
                        onChanged: null,
                      ),
                      SizedBox(width: 8),
                      Text(language.displayName),
                    ],
                  ),
                );
              }).toList();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  appLanguage.code.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          farmsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading farms',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => ref.refresh(farmsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (farms) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Agri-Pulse Quick Access Cards
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Access',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _buildQuickAccessCard(
                                context,
                                '🎯 Decision\nBoard',
                                'Get expert\nadvice',
                                Colors.blue,
                                () => context.push('/decision-board'),
                              ),
                              _buildQuickAccessCard(
                                context,
                                '🗺️ Living\nMap',
                                'Explore\nopportunities',
                                Colors.green,
                                () => context.push('/living-map'),
                              ),
                              _buildQuickAccessCard(
                                context,
                                '✨ Magic\nSnap',
                                'Claim your\nland',
                                Colors.orange,
                                () => context.push('/magic-snap'),
                              ),
                              _buildQuickAccessCard(
                                context,
                                '💬 Chat',
                                'Connect with\nbuyers',
                                Colors.purple,
                                () => context.push('/chat'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // My Farms Section
                    if (farms.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'My Farms',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (farms.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.agriculture_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No farms yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use Magic Snap to claim your first field',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/magic-snap'),
                              icon: const Icon(Icons.add),
                              label: const Text('Claim Land'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: farms.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final farm = farms[index];
                          return _buildFarmCard(farm, context);
                        },
                      ),
                  ],
                ),
              );
            },
          ),

          // Offline indicator
          if (!networkState.isOnline)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'You are offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (syncState.isSyncing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Sync indicator
          if (syncState.pendingChanges > 0 && !syncState.isSyncing)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => ref.read(syncProvider.notifier).syncAll(),
                tooltip: '${syncState.pendingChanges} pending changes',
                child: Badge(
                  label: Text('${syncState.pendingChanges}'),
                  child: const Icon(Icons.cloud_upload_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.agriculture,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          farm['name'] ?? 'Farm',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              farm['location'] ?? 'Unknown location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (farm['crop_type'] != null)
                  Chip(
                    label: Text(farm['crop_type']),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.primary),
                  ),
                if (farm['area_acres'] != null)
                  Chip(
                    label: Text('${farm['area_acres']} acres'),
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    labelStyle: const TextStyle(color: AppColors.secondary),
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {},
        ),
      ),
    );
  }
}

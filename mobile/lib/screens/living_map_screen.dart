import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlai_crop/generated_l10n/app_localizations.dart';
import '../models/agri_pulse_models.dart';
import '../providers/mock_data_provider.dart';

class LivingMapScreen extends ConsumerStatefulWidget {
  const LivingMapScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LivingMapScreen> createState() => _LivingMapScreenState();
}

class _LivingMapScreenState extends ConsumerState<LivingMapScreen> {
  String selectedMode = 'myCrops'; // 'myCrops', 'services', 'buyFresh'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.livingMap),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map Background (Placeholder)
          _buildMapPlaceholder(context),

          // Top Omnibox
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildOmnibox(context, l10n),
          ),

          // Mode Filter Chips
          Positioned(
            top: 76,
            left: 16,
            right: 16,
            child: _buildModeChips(context, l10n),
          ),

          // Bottom Action Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildModeContent(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
    return Container(
      color: Color(0xFFE8F5E9),
      child: Stack(
        children: [
          // Grid pattern for map background
          GridView.count(
            crossAxisCount: 8,
            children: List.generate(64, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green[100]!,
                    width: 0.5,
                  ),
                ),
              );
            }),
          ),

          // Satellite heatmap placeholder
          Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🛰️',
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Satellite Map',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Real satellite imagery + AI layers coming soon',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmnibox(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchLocation,
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.tune),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildModeChips(BuildContext context, AppLocalizations l10n) {
    final modes = [
      {'id': 'myCrops', 'label': l10n.myCrops, 'icon': '🌾'},
      {'id': 'services', 'label': l10n.services, 'icon': '🔧'},
      {'id': 'buyFresh', 'label': l10n.buyFresh, 'icon': '🥬'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: modes.map((mode) {
          final isSelected = selectedMode == mode['id'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mode['icon'] as String),
                  SizedBox(width: 6),
                  Text(mode['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  selectedMode = mode['id'] as String;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.green[300],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeContent(BuildContext context, AppLocalizations l10n) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: _buildModePanel(context, l10n),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModePanel(BuildContext context, AppLocalizations l10n) {
    switch (selectedMode) {
      case 'myCrops':
        return _buildMycropsMode(context, l10n);
      case 'services':
        return _buildServicesMode(context, l10n);
      case 'buyFresh':
        return _buildBuyFreshMode(context, l10n);
      default:
        return SizedBox();
    }
  }

  Widget _buildMycropsMode(BuildContext context, AppLocalizations l10n) {
    final farms = ref.watch(myFarmsProvider);
    final weather = ref.watch(weatherDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🌾 ${l10n.myCropsTitle}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Icon(Icons.more_vert),
          ],
        ),
        SizedBox(height: 16),
        ...farms.map((farm) {
          return _buildFarmCard(context, l10n, farm, weather);
        }).toList(),
      ],
    );
  }

  Widget _buildFarmCard(BuildContext context, AppLocalizations l10n,
      FarmData farm, WeatherData weather) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.green[100]!,
                  Colors.yellow[100]!,
                  Colors.red[100]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                '🗺️',
                style: TextStyle(fontSize: 48),
              ),
            ),
          ),

          // Farm Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${farm.cropType} • ${farm.acreage} acres',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${farm.daysToHarvest}d left',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Progress indicators
                Row(
                  children: [
                    _buildProgressIndicator(
                      label: 'Soil Health',
                      value: farm.soilHealth,
                      color: Colors.green,
                    ),
                    SizedBox(width: 12),
                    _buildProgressIndicator(
                      label: 'Pest Risk',
                      value: 100 - farm.pestRisk,
                      color: Colors.red,
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

  Widget _buildProgressIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesMode(BuildContext context, AppLocalizations l10n) {
    final pins = ref.watch(servicePinsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🔧 ${l10n.servicesTitle}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Icon(Icons.more_vert),
          ],
        ),
        SizedBox(height: 16),
        ...pins.map((pin) {
          return _buildServiceCard(context, l10n, pin);
        }).toList(),
      ],
    );
  }

  Widget _buildServiceCard(
      BuildContext context, AppLocalizations l10n, ServicePin pin) {
    final typeEmoji = pin.type == 'mechanic'
        ? '👨‍🔧'
        : pin.type == 'transporter'
            ? '🚚'
            : '🐛';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pin.urgency == 'urgent'
                        ? Colors.red[100]
                        : Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(typeEmoji, style: TextStyle(fontSize: 24)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pin.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pin.urgency == 'urgent'
                                  ? Colors.red[500]
                                  : Colors.yellow[500],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pin.urgency.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.orange[600]),
                          SizedBox(width: 4),
                          Text(
                            '${pin.rating}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              pin.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${pin.name}...')),
                      );
                    },
                    icon: Icon(Icons.phone),
                    label: Text(l10n.callNow),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening chat with ${pin.name}...')),
                    );
                  },
                  icon: Icon(Icons.message),
                  label: Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyFreshMode(BuildContext context, AppLocalizations l10n) {
    final items = ref.watch(produceItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🥬 ${l10n.buyFreshTitle}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Icon(Icons.more_vert),
          ],
        ),
        SizedBox(height: 16),
        ...items.map((item) {
          return _buildProduceCard(context, l10n, item);
        }).toList(),
      ],
    );
  }

  Widget _buildProduceCard(
      BuildContext context, AppLocalizations l10n, ProduceItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with vitality ring
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.green[100],
                ),
                child: Center(
                  child: Text(
                    item.cropType == 'Tomato'
                        ? '🍅'
                        : item.cropType == 'Spinach'
                            ? '🌿'
                            : '🧅',
                    style: TextStyle(fontSize: 64),
                  ),
                ),
              ),

              // Vitality ring
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.bioVitalityScore > 90
                          ? Colors.green[400]!
                          : Colors.yellow[400]!,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.bioVitalityScore > 90
                            ? Colors.green[400]!.withOpacity(0.5)
                            : Colors.yellow[400]!.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✓', style: TextStyle(fontSize: 24)),
                        Text(
                          '${item.bioVitalityScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.farmName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'by ${item.farmerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${item.pricePerKg.toStringAsFixed(0)}/kg',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '⏱️ Harvested ${item.harvestedHoursAgo}h ago • 🌱 Soil: ${item.soilHealthScore.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${item.cropType} added to cart! Delivery available.'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      '🛒 Add to Cart',
                      style: TextStyle(color: Colors.white),
                    ),
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

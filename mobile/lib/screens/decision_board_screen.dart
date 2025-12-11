import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/agri_pulse_models.dart';
import '../providers/mock_data_provider.dart';
import '../services/localization_service.dart';

class DecisionBoardScreen extends ConsumerStatefulWidget {
  const DecisionBoardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DecisionBoardScreen> createState() =>
      _DecisionBoardScreenState();
}

class _DecisionBoardScreenState extends ConsumerState<DecisionBoardScreen> {
  CropOption? selectedCrop;
  GrowthStage? selectedStage;
  bool showVerdict = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final crops = ref.watch(cropOptionsProvider);
    final stages = ref.watch(growthStagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.decisionBoard),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌾 ${l10n.decisionBoardDesc}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select your crop and growth stage to get AI-powered advice',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Crop Selection Section
            Text(
              l10n.selectCrop,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: crops.length,
                itemBuilder: (context, index) {
                  final crop = crops[index];
                  final isSelected = selectedCrop?.id == crop.id;
                  return Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCrop = crop;
                          showVerdict = false;
                        });
                      },
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          color: isSelected ? Colors.green[50] : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              crop.imageUrl.contains('Wheat')
                                  ? '🌾'
                                  : crop.imageUrl.contains('Rice')
                                      ? '🍚'
                                      : crop.imageUrl.contains('Corn')
                                          ? '🌽'
                                          : crop.imageUrl.contains('Cotton')
                                              ? '🏵️'
                                              : crop.imageUrl.contains('Tomato')
                                                  ? '🍅'
                                                  : '🧅',
                              style: TextStyle(fontSize: 32),
                            ),
                            SizedBox(height: 8),
                            Text(
                              crop.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            // Growth Stage Selection
            Text(
              l10n.selectStage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stages.map((stage) {
                final isSelected = selectedStage?.id == stage.id;
                return FilterChip(
                  label: Text(stage.name),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedStage = selected ? stage : null;
                      showVerdict = false;
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Colors.green[300],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Get Advice Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedCrop != null && selectedStage != null
                    ? () {
                        setState(() {
                          showVerdict = true;
                        });
                      }
                    : null,
                icon: Icon(Icons.lightbulb),
                label: Text(l10n.getAdvice),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Verdict Card
            if (showVerdict) ...[
              _buildVerdictCard(context, l10n),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictCard(BuildContext context, AppLocalizations l10n) {
    final verdict = ref.watch(aiVerdictProvider);
    final weather = ref.watch(weatherDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      verdict.emoji,
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.verdict,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            verdict.verdict,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(verdict.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verdict.explanation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Current Weather Widget
        Card(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.weather} 🌡️',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _weatherMetric(
                      label: 'Temperature',
                      value: '${weather.temperature.toStringAsFixed(1)}°C',
                      icon: '🌡️',
                    ),
                    _weatherMetric(
                      label: 'Humidity',
                      value: '${weather.humidity.toStringAsFixed(0)}%',
                      icon: '💧',
                    ),
                    _weatherMetric(
                      label: 'Wind Speed',
                      value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                      icon: '💨',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Recommendation Card
        Card(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Recommendation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12),
                Text(
                  verdict.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Login Prompt
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            border: Border.all(color: Colors.amber[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[800]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Login to get precise, field-specific advice tailored to your exact soil and climate data.',
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _weatherMetric({
    required String label,
    required String value,
    required String icon,
  }) {
    return Column(
      children: [
        Text(icon, style: TextStyle(fontSize: 24)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

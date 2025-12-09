import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_ai/core/localization/app_localizations.dart';
import 'package:crop_ai/features/farm/models/farm.dart';
import 'package:crop_ai/features/farm/models/farm_form.dart';
import 'package:crop_ai/features/farm/providers/farm_provider.dart';
import 'package:crop_ai/features/offline_sync/data/sync_service.dart';

class AddEditFarmScreen extends ConsumerStatefulWidget {
  final String? farmId;

  const AddEditFarmScreen({
    this.farmId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AddEditFarmScreen> createState() => _AddEditFarmScreenState();
}

class _AddEditFarmScreenState extends ConsumerState<AddEditFarmScreen> {
  late FarmFormModel _formModel;
  late GlobalKey<FormState> _formKey;
  late TextEditingController _nameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _areaController;
  late TextEditingController _moistureController;
  late TextEditingController _temperatureController;

  bool _isLoading = false;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _formModel = FarmFormModel.empty();

    _nameController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _areaController = TextEditingController();
    _moistureController = TextEditingController();
    _temperatureController = TextEditingController();

    _loadFarmData();
  }

  void _loadFarmData() async {
    if (widget.farmId != null) {
      // Load existing farm for editing
      final farmAsync = ref.read(farmByIdProvider(widget.farmId!));
      await farmAsync.when(
        data: (farm) {
          if (farm != null) {
            _formModel = FarmFormModel.fromFarm(farm);
            _updateControllers();
          }
        },
        loading: () {},
        error: (err, stack) {},
      );
    }
  }

  void _updateControllers() {
    _nameController.text = _formModel.name;
    _latitudeController.text = _formModel.latitude.toString();
    _longitudeController.text = _formModel.longitude.toString();
    _areaController.text = _formModel.areaHectares.toString();
    _moistureController.text = _formModel.soilMoisture.toString();
    _temperatureController.text = _formModel.temperature.toString();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedPhotoPath = image.path;
          _formModel = _formModel.copyWith(photoPath: image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update model with controller values
      _formModel = _formModel.copyWith(
        name: _nameController.text,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        areaHectares: double.parse(_areaController.text),
        soilMoisture: double.parse(_moistureController.text),
        temperature: double.parse(_temperatureController.text),
      );

      final farm = _formModel.toFarm();

      // Add to farm repository
      if (widget.farmId == null) {
        // New farm - queue create operation
        await ref.read(farmListNotifierProvider.notifier).addFarm(farm);
        ref.read(syncServiceProvider).queueFarmOperation(
          farm.id,
          'create',
          farm.toMap(),
        );
      } else {
        // Update farm - queue update operation
        await ref.read(farmListNotifierProvider.notifier).updateFarm(farm);
        ref.read(syncServiceProvider).queueFarmOperation(
          farm.id,
          'update',
          farm.toMap(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.farmId == null ? 'Farm added successfully' : 'Farm updated successfully'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving farm: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmId == null ? (i18n?.farmAddFarm ?? 'Add Farm') : (i18n?.edit ?? 'Edit')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo section
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: _selectedPhotoPath != null
                    ? Image.file(
                        _selectedPhotoPath as dynamic,
                        fit: BoxFit.cover,
                      )
                    : InkWell(
                        onTap: _pickImage,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48, color: theme.colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('${i18n?.add ?? 'Add'} Photo'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Farm name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: i18n?.farmLocation ?? 'Farm Name',
                  hintText: 'Enter farm name',
                  prefixIcon: const Icon(Icons.agriculture),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: FormValidation.validateFarmName,
              ),
              const SizedBox(height: 16),

              // Crop type dropdown
              DropdownButtonFormField<String>(
                value: _formModel.cropType,
                decoration: InputDecoration(
                  labelText: i18n?.farmCropType ?? 'Crop Type',
                  prefixIcon: const Icon(Icons.eco),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: CropType.options.map((crop) {
                  return DropdownMenuItem(
                    value: crop,
                    child: Row(
                      children: [
                        Text(CropType.emoji[crop] ?? '🌾'),
                        const SizedBox(width: 8),
                        Text(crop),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _formModel = _formModel.copyWith(cropType: value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Area
              TextFormField(
                controller: _areaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${i18n?.farmArea ?? 'Area'} (${i18n?.farmHectares ?? 'hectares'})',
                  hintText: '0.0',
                  prefixIcon: const Icon(Icons.square_foot),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: FormValidation.validateArea,
              ),
              const SizedBox(height: 16),

              // Coordinates row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        hintText: '0.0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => FormValidation.validateCoordinate(value, 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        hintText: '0.0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => FormValidation.validateCoordinate(value, 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Planting date
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: i18n?.farmPlantingDate ?? 'Planting Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                controller: TextEditingController(
                  text: _formModel.plantingDate.toString().split(' ')[0],
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _formModel.plantingDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _formModel = _formModel.copyWith(plantingDate: date);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Soil moisture
              TextFormField(
                controller: _moistureController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${i18n?.farmSoilMoisture ?? 'Soil Moisture'} (%)',
                  hintText: '50.0',
                  prefixIcon: const Icon(Icons.water_drop),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: FormValidation.validateMoisture,
              ),
              const SizedBox(height: 16),

              // Temperature
              TextFormField(
                controller: _temperatureController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: '${i18n?.farmTemperature ?? 'Temperature'} (°C)',
                  hintText: '25.0',
                  prefixIcon: const Icon(Icons.thermostat),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: FormValidation.validateTemperature,
              ),
              const SizedBox(height: 16),

              // Health status
              DropdownButtonFormField<String>(
                value: _formModel.healthStatus,
                decoration: InputDecoration(
                  labelText: i18n?.farmHealthStatus ?? 'Health Status',
                  prefixIcon: const Icon(Icons.favorite),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: HealthStatus.options.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HealthStatus.colors[status],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        HealthStatus.labels[status] ?? status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _formModel = _formModel.copyWith(healthStatus: value);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Submit buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: Text(i18n?.cancel ?? 'Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveFarm,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(i18n?.save ?? 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _areaController.dispose();
    _moistureController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }
}

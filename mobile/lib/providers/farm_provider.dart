import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// Models for Farm data
class Farm {
  final String id;
  final String userId;
  final String name;
  final String location;
  final double area;
  final String farmType;
  final String currentCrop;
  final String growthStage;
  final double soilHealthScore;
  final double moistureLevel;
  final double phLevel;

  Farm({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.area,
    required this.farmType,
    required this.currentCrop,
    required this.growthStage,
    required this.soilHealthScore,
    required this.moistureLevel,
    required this.phLevel,
  });

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Unknown',
    location: json['location'] as String? ?? 'N/A',
    area: (json['area'] as num?)?.toDouble() ?? 0.0,
    farmType: json['farm_type'] as String? ?? 'Vegetable',
    currentCrop: json['current_crop'] as String? ?? 'Wheat',
    growthStage: json['growth_stage'] as String? ?? 'Planting',
    soilHealthScore: (json['soil_health_score'] as num?)?.toDouble() ?? 50.0,
    moistureLevel: (json['moisture_level'] as num?)?.toDouble() ?? 50.0,
    phLevel: (json['ph_level'] as num?)?.toDouble() ?? 7.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'location': location,
    'area': area,
    'farm_type': farmType,
    'current_crop': currentCrop,
    'growth_stage': growthStage,
    'soil_health_score': soilHealthScore,
    'moisture_level': moistureLevel,
    'ph_level': phLevel,
  };

  Farm copyWith({
    String? id,
    String? userId,
    String? name,
    String? location,
    double? area,
    String? farmType,
    String? currentCrop,
    String? growthStage,
    double? soilHealthScore,
    double? moistureLevel,
    double? phLevel,
  }) =>
      Farm(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        location: location ?? this.location,
        area: area ?? this.area,
        farmType: farmType ?? this.farmType,
        currentCrop: currentCrop ?? this.currentCrop,
        growthStage: growthStage ?? this.growthStage,
        soilHealthScore: soilHealthScore ?? this.soilHealthScore,
        moistureLevel: moistureLevel ?? this.moistureLevel,
        phLevel: phLevel ?? this.phLevel,
      );
}

// HTTP Client Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  // In production, configure with actual API base URL from environment
  dio.options.baseUrl = 'http://localhost:8000/api';
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return dio;
});

// Farm List Provider - fetches farms from backend API
final farmListProvider = FutureProvider<List<Farm>>((ref) async {
  final dio = ref.watch(dioProvider);
  
  try {
    // Mock data for offline development - remove when API is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final response = await dio.get('/farm/farmer/farms');
    
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final farmsData = data['farms'] as List<dynamic>? ?? [];
      
      return farmsData
          .map((farm) => Farm.fromJson(farm as Map<String, dynamic>))
          .toList();
    }
    
    throw Exception('Failed to load farms: ${response.statusCode}');
  } catch (e) {
    // Fallback to mock data for development
    return _getMockFarms();
  }
});

// Refresh farm list provider
final refreshFarmListProvider =
    FutureProvider.autoDispose<void>((ref) async {
  ref.refresh(farmListProvider);
});

// Mock data for development
List<Farm> _getMockFarms() => [
  Farm(
    id: 'farm_001',
    userId: 'user_001',
    name: 'Green Valley Farm',
    location: 'Jaipur, Rajasthan',
    area: 15.5,
    farmType: 'Vegetable',
    currentCrop: 'Tomato',
    growthStage: 'Flowering',
    soilHealthScore: 72.0,
    moistureLevel: 65.0,
    phLevel: 6.8,
  ),
  Farm(
    id: 'farm_002',
    userId: 'user_001',
    name: 'Wheat Field North',
    location: 'Ludhiana, Punjab',
    area: 25.0,
    farmType: 'Cereal',
    currentCrop: 'Wheat',
    growthStage: 'Growth',
    soilHealthScore: 68.0,
    moistureLevel: 58.0,
    phLevel: 7.2,
  ),
  Farm(
    id: 'farm_003',
    userId: 'user_001',
    name: 'Organic Dairy Farm',
    location: 'Nashik, Maharashtra',
    area: 8.0,
    farmType: 'Dairy',
    currentCrop: 'Maize + Fodder',
    growthStage: 'Vegetative',
    soilHealthScore: 78.0,
    moistureLevel: 72.0,
    phLevel: 6.9,
  ),
];

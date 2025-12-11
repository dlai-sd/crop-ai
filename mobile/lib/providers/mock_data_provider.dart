import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agri_pulse_models.dart';

/// Mock data for Agri-Pulse features

final cropOptionsProvider = Provider<List<CropOption>>((ref) {
  return [
    CropOption(
      id: 'wheat',
      name: 'Wheat',
      imageUrl: 'https://via.placeholder.com/150?text=Wheat',
    ),
    CropOption(
      id: 'rice',
      name: 'Rice',
      imageUrl: 'https://via.placeholder.com/150?text=Rice',
    ),
    CropOption(
      id: 'corn',
      name: 'Corn',
      imageUrl: 'https://via.placeholder.com/150?text=Corn',
    ),
    CropOption(
      id: 'cotton',
      name: 'Cotton',
      imageUrl: 'https://via.placeholder.com/150?text=Cotton',
    ),
    CropOption(
      id: 'tomato',
      name: 'Tomato',
      imageUrl: 'https://via.placeholder.com/150?text=Tomato',
    ),
    CropOption(
      id: 'onion',
      name: 'Onion',
      imageUrl: 'https://via.placeholder.com/150?text=Onion',
    ),
  ];
});

final growthStagesProvider = Provider<List<GrowthStage>>((ref) {
  return [
    GrowthStage(id: 'planning', name: 'Planning', daysInStage: 7),
    GrowthStage(id: 'sowing', name: 'Sowing', daysInStage: 3),
    GrowthStage(id: 'germination', name: 'Germination', daysInStage: 10),
    GrowthStage(id: 'vegetative', name: 'Vegetative', daysInStage: 35),
    GrowthStage(id: 'flowering', name: 'Flowering', daysInStage: 15),
    GrowthStage(id: 'fruiting', name: 'Fruiting', daysInStage: 20),
    GrowthStage(id: 'maturity', name: 'Maturity', daysInStage: 10),
  ];
});

final aiVerdictProvider = Provider<AIVerdict>((ref) {
  return AIVerdict(
    verdict: 'Go Ahead',
    emoji: '🙂',
    explanation:
        'Optimal soil moisture and temperature for wheat planting in your region.',
    recommendation:
        'Sow high-quality seeds within the next 3-5 days. Apply balanced NPK fertilizer.',
    confidenceScore: 0.92,
  );
});

final weatherDataProvider = Provider<WeatherData>((ref) {
  return WeatherData(
    temperature: 22.5,
    humidity: 65.0,
    windSpeed: 8.5,
    condition: 'Partly Cloudy',
    iconUrl: '🌤️',
    rainfall: 2.5,
  );
});

final myFarmsProvider = Provider<List<FarmData>>((ref) {
  return [
    FarmData(
      id: 'farm1',
      name: 'Ramesh Field North',
      latitude: 28.6139,
      longitude: 77.2090,
      acreage: 12.5,
      cropType: 'Wheat',
      daysToHarvest: 28,
      soilHealth: 78.0,
      pestRisk: 15.0,
      coordinates: [
        [28.6139, 77.2090],
        [28.6150, 77.2100],
        [28.6145, 77.2110],
      ],
    ),
    FarmData(
      id: 'farm2',
      name: 'Ramesh Field South',
      latitude: 28.6100,
      longitude: 77.2050,
      acreage: 8.0,
      cropType: 'Mustard',
      daysToHarvest: 35,
      soilHealth: 82.0,
      pestRisk: 8.0,
      coordinates: [
        [28.6100, 77.2050],
        [28.6110, 77.2060],
        [28.6105, 77.2070],
      ],
    ),
  ];
});

final servicePinsProvider = Provider<List<ServicePin>>((ref) {
  return [
    ServicePin(
      id: 'service1',
      type: 'mechanic',
      name: 'Vikram Singh',
      title: 'Tractor Repair',
      latitude: 28.6145,
      longitude: 77.2095,
      urgency: 'urgent',
      description: 'Tractor breakdown reported in sector 5. Emergency service available.',
      phoneNumber: '+91 98765 43210',
      rating: 4.8,
    ),
    ServicePin(
      id: 'service2',
      type: 'transporter',
      name: 'Sharma Logistics',
      title: 'Farm Transport',
      latitude: 28.6120,
      longitude: 77.2080,
      urgency: 'predicted',
      description: 'Harvest expected in 2 days. We can provide transport vehicles.',
      phoneNumber: '+91 98765 43211',
      rating: 4.5,
    ),
    ServicePin(
      id: 'service3',
      type: 'pestControl',
      name: 'Dr. Anand Patel',
      title: 'Pest Control Expert',
      latitude: 28.6110,
      longitude: 77.2110,
      urgency: 'predicted',
      description: 'Armyworm detected in 5km radius. Free consultation available.',
      phoneNumber: '+91 98765 43212',
      rating: 4.9,
    ),
  ];
});

final produceItemsProvider = Provider<List<ProduceItem>>((ref) {
  return [
    ProduceItem(
      id: 'prod1',
      farmName: 'Sundar Organic Farm',
      cropType: 'Tomato',
      pricePerKg: 35.0,
      harvestedHoursAgo: 2,
      bioVitalityScore: 95.0,
      soilHealthScore: 88.0,
      farmImageUrl: 'https://via.placeholder.com/300x200?text=Fresh+Tomatoes',
      farmerName: 'Sundar Kumar',
      farmerPhone: '+91 98765 43220',
      latitude: 28.6155,
      longitude: 77.2105,
    ),
    ProduceItem(
      id: 'prod2',
      farmName: 'Priya Vegetable Garden',
      cropType: 'Spinach',
      pricePerKg: 25.0,
      harvestedHoursAgo: 4,
      bioVitalityScore: 92.0,
      soilHealthScore: 85.0,
      farmImageUrl: 'https://via.placeholder.com/300x200?text=Fresh+Spinach',
      farmerName: 'Priya Singh',
      farmerPhone: '+91 98765 43221',
      latitude: 28.6125,
      longitude: 77.2075,
    ),
    ProduceItem(
      id: 'prod3',
      farmName: 'Rajesh Onion Field',
      cropType: 'Onion',
      pricePerKg: 30.0,
      harvestedHoursAgo: 12,
      bioVitalityScore: 85.0,
      soilHealthScore: 80.0,
      farmImageUrl: 'https://via.placeholder.com/300x200?text=Fresh+Onions',
      farmerName: 'Rajesh Verma',
      farmerPhone: '+91 98765 43222',
      latitude: 28.6090,
      longitude: 77.2040,
    ),
  ];
});

final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return [
    ChatMessage(
      id: 'msg1',
      senderId: 'service1',
      senderName: 'Vikram Singh',
      senderAvatar: '👨‍🔧',
      message: 'Hi Ramesh! I can be at your field in 30 minutes.',
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      isFromMe: false,
    ),
    ChatMessage(
      id: 'msg2',
      senderId: 'user1',
      senderName: 'You',
      senderAvatar: '👨‍🌾',
      message: 'Great! The tractor is in the north field near the gate.',
      timestamp: DateTime.now().subtract(Duration(minutes: 2)),
      isFromMe: true,
    ),
    ChatMessage(
      id: 'msg3',
      senderId: 'service1',
      senderName: 'Vikram Singh',
      senderAvatar: '👨‍🔧',
      message: 'I am offering ₹1,500 for the repair job. Can you accept?',
      timestamp: DateTime.now(),
      isFromMe: false,
    ),
  ];
});

final smartChipsProvider = Provider<List<SmartChip>>((ref) {
  return [
    SmartChip(
      action: 'accept_bid',
      label: 'Accept Bid',
      value: '₹1,500',
    ),
    SmartChip(
      action: 'share_location',
      label: 'Share Location',
      value: '28.6139, 77.2090',
    ),
    SmartChip(
      action: 'counter_offer',
      label: 'Counter Offer',
      value: '₹1,200',
    ),
  ];
});

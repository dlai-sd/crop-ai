/// Dummy data models for Agri-Pulse modules

class CropOption {
  final String id;
  final String name;
  final String imageUrl;

  CropOption({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
}

class GrowthStage {
  final String id;
  final String name;
  final int daysInStage;

  GrowthStage({
    required this.id,
    required this.name,
    required this.daysInStage,
  });
}

class AIVerdict {
  final String verdict;
  final String emoji;
  final String explanation;
  final String recommendation;
  final double confidenceScore;

  AIVerdict({
    required this.verdict,
    required this.emoji,
    required this.explanation,
    required this.recommendation,
    required this.confidenceScore,
  });
}

class WeatherData {
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final String iconUrl;
  final double rainfall;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.iconUrl,
    required this.rainfall,
  });
}

class FarmData {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double acreage;
  final String cropType;
  final int daysToHarvest;
  final double soilHealth;
  final double pestRisk;
  final List<double> coordinates;

  FarmData({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.acreage,
    required this.cropType,
    required this.daysToHarvest,
    required this.soilHealth,
    required this.pestRisk,
    required this.coordinates,
  });
}

class ServicePin {
  final String id;
  final String type; // 'mechanic', 'transporter', 'pestControl'
  final String name;
  final String title;
  final double latitude;
  final double longitude;
  final String urgency; // 'urgent' or 'predicted'
  final String description;
  final String phoneNumber;
  final double rating;

  ServicePin({
    required this.id,
    required this.type,
    required this.name,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.urgency,
    required this.description,
    required this.phoneNumber,
    required this.rating,
  });
}

class ProduceItem {
  final String id;
  final String farmName;
  final String cropType;
  final double pricePerKg;
  final int harvestedHoursAgo;
  final double bioVitalityScore;
  final double soilHealthScore;
  final String farmImageUrl;
  final String farmerName;
  final String farmerPhone;
  final double latitude;
  final double longitude;

  ProduceItem({
    required this.id,
    required this.farmName,
    required this.cropType,
    required this.pricePerKg,
    required this.harvestedHoursAgo,
    required this.bioVitalityScore,
    required this.soilHealthScore,
    required this.farmImageUrl,
    required this.farmerName,
    required this.farmerPhone,
    required this.latitude,
    required this.longitude,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String message;
  final DateTime timestamp;
  final bool isFromMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.message,
    required this.timestamp,
    required this.isFromMe,
  });
}

class SmartChip {
  final String action;
  final String label;
  final String value;

  SmartChip({
    required this.action,
    required this.label,
    required this.value,
  });
}

class MagicSnapResult {
  final List<List<double>> polygonCoordinates;
  final double acreage;
  final bool isValidated;
  final String validationMessage;

  MagicSnapResult({
    required this.polygonCoordinates,
    required this.acreage,
    required this.isValidated,
    required this.validationMessage,
  });
}

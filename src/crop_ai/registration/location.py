"""
Location services for registration.

Provides:
- GPS coordinate validation
- Current location retrieval
- Map picker integration
- Address geocoding
- Location accuracy assessment
"""
from typing import Optional, Tuple, List
from pydantic import BaseModel, validator, Field
from dataclasses import dataclass
from math import radians, cos, sin, asin, sqrt
import httpx


# ============================================================================
# Location Models
# ============================================================================

class GPSCoordinates(BaseModel):
    """GPS coordinates."""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude (-90 to 90)")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude (-180 to 180)")
    accuracy: Optional[float] = Field(None, ge=0, description="Accuracy in meters")
    
    @validator("latitude", "longitude", pre=True)
    def round_coordinates(cls, v):
        """Round to 6 decimal places (~0.1m precision)."""
        if isinstance(v, (int, float)):
            return round(v, 6)
        return v


class Address(BaseModel):
    """Address information."""
    street: Optional[str] = Field(None, max_length=255, description="Street address")
    city: str = Field(..., min_length=2, max_length=100, description="City")
    state: str = Field(..., min_length=2, max_length=100, description="State/Province")
    postal_code: Optional[str] = Field(None, max_length=20, description="Postal code")
    country: str = Field(default="India", max_length=100, description="Country")
    
    def to_string(self) -> str:
        """Convert address to readable string."""
        parts = [self.street, self.city, self.state, self.postal_code, self.country]
        return ", ".join(str(p) for p in parts if p)


class LocationData(BaseModel):
    """Complete location data."""
    coordinates: GPSCoordinates
    address: Address
    source: str = Field(
        default="manual",
        description="Source: manual, gps, map_selected, geocoded"
    )
    confidence: float = Field(
        default=0.8,
        ge=0.0,
        le=1.0,
        description="Confidence score (0-1)"
    )


@dataclass
class BoundingBox:
    """Bounding box for geographic region."""
    north: float  # Max latitude
    south: float  # Min latitude
    east: float   # Max longitude
    west: float   # Min longitude
    
    def contains(self, latitude: float, longitude: float) -> bool:
        """Check if coordinates are within bounding box."""
        return (
            self.south <= latitude <= self.north and
            self.west <= longitude <= self.east
        )


# ============================================================================
# Location Validation
# ============================================================================

class LocationValidator:
    """Validate location data."""
    
    # India bounding box (extended with buffer)
    INDIA_BOUNDS = BoundingBox(
        north=35.5,      # North: ~Himachal Pradesh
        south=8.0,       # South: ~Kerala
        east=97.5,       # East: ~Arunachal Pradesh
        west=68.0,       # West: ~Gujarat
    )
    
    # Common location accuracy thresholds (meters)
    GPS_ACCURACY_EXCELLENT = 10
    GPS_ACCURACY_GOOD = 50
    GPS_ACCURACY_ACCEPTABLE = 100
    GPS_ACCURACY_POOR = 500
    
    @staticmethod
    def validate_coordinates(latitude: float, longitude: float) -> Tuple[bool, Optional[str]]:
        """
        Validate GPS coordinates.
        
        Returns:
            (is_valid, error_message)
        """
        if not (-90 <= latitude <= 90):
            return False, f"Latitude must be between -90 and 90, got {latitude}"
        
        if not (-180 <= longitude <= 180):
            return False, f"Longitude must be between -180 and 180, got {longitude}"
        
        # Check if coordinates are valid (not 0,0 or Null Island)
        if latitude == 0.0 and longitude == 0.0:
            return False, "Invalid coordinates (0, 0) - Null Island"
        
        return True, None
    
    @staticmethod
    def validate_for_india(latitude: float, longitude: float) -> Tuple[bool, Optional[str]]:
        """
        Validate if coordinates are within India.
        
        Returns:
            (is_valid, error_message)
        """
        is_valid, error = LocationValidator.validate_coordinates(latitude, longitude)
        if not is_valid:
            return False, error
        
        if not LocationValidator.INDIA_BOUNDS.contains(latitude, longitude):
            return False, f"Coordinates ({latitude}, {longitude}) are not in India"
        
        return True, None
    
    @staticmethod
    def assess_gps_accuracy(accuracy_meters: float) -> str:
        """Assess GPS accuracy level."""
        if accuracy_meters <= LocationValidator.GPS_ACCURACY_EXCELLENT:
            return "excellent"
        elif accuracy_meters <= LocationValidator.GPS_ACCURACY_GOOD:
            return "good"
        elif accuracy_meters <= LocationValidator.GPS_ACCURACY_ACCEPTABLE:
            return "acceptable"
        elif accuracy_meters <= LocationValidator.GPS_ACCURACY_POOR:
            return "poor"
        else:
            return "very_poor"
    
    @staticmethod
    def validate_location_data(location: LocationData) -> Tuple[bool, Optional[str]]:
        """Validate complete location data."""
        # Validate coordinates
        is_valid, error = LocationValidator.validate_for_india(
            location.coordinates.latitude,
            location.coordinates.longitude,
        )
        if not is_valid:
            return False, error
        
        # Validate accuracy if provided
        if location.coordinates.accuracy:
            if location.coordinates.accuracy > 10000:  # > 10 km
                return False, f"GPS accuracy {location.coordinates.accuracy}m seems too high"
        
        # Validate address
        if not location.address.city:
            return False, "City is required"
        
        if not location.address.state:
            return False, "State is required"
        
        return True, None


# ============================================================================
# Geocoding Service
# ============================================================================

class GeocodeProvider:
    """Base geocoding provider interface."""
    
    async def geocode_address(self, address: Address) -> Optional[GPSCoordinates]:
        """Convert address to GPS coordinates."""
        raise NotImplementedError
    
    async def reverse_geocode(
        self,
        latitude: float,
        longitude: float,
    ) -> Optional[Address]:
        """Convert GPS coordinates to address."""
        raise NotImplementedError


class GoogleMapsGeocoder(GeocodeProvider):
    """Google Maps Geocoding API provider."""
    
    GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"
    
    def __init__(self, api_key: str):
        """Initialize with Google Maps API key."""
        self.api_key = api_key
    
    async def geocode_address(self, address: Address) -> Optional[GPSCoordinates]:
        """Geocode address to GPS coordinates."""
        try:
            address_str = address.to_string()
            
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    self.GEOCODE_URL,
                    params={
                        "address": address_str,
                        "key": self.api_key,
                    },
                    timeout=10,
                )
                response.raise_for_status()
                data = response.json()
                
                if data.get("status") == "OK" and data.get("results"):
                    location = data["results"][0]["geometry"]["location"]
                    accuracy = data["results"][0]["geometry"].get("location_type")
                    
                    return GPSCoordinates(
                        latitude=location["lat"],
                        longitude=location["lng"],
                        accuracy=None,
                    )
        except Exception as e:
            print(f"Geocoding error: {e}")
        
        return None
    
    async def reverse_geocode(
        self,
        latitude: float,
        longitude: float,
    ) -> Optional[Address]:
        """Reverse geocode GPS coordinates to address."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    self.GEOCODE_URL,
                    params={
                        "latlng": f"{latitude},{longitude}",
                        "key": self.api_key,
                    },
                    timeout=10,
                )
                response.raise_for_status()
                data = response.json()
                
                if data.get("status") == "OK" and data.get("results"):
                    address_components = data["results"][0]["address_components"]
                    formatted = data["results"][0]["formatted_address"]
                    
                    # Extract address components
                    components = {}
                    for component in address_components:
                        types = component.get("types", [])
                        if "street_number" in types or "route" in types:
                            components["street"] = component.get("long_name")
                        if "locality" in types or "administrative_area_level_3" in types:
                            components["city"] = component.get("long_name")
                        if "administrative_area_level_1" in types:
                            components["state"] = component.get("long_name")
                        if "postal_code" in types:
                            components["postal_code"] = component.get("long_name")
                        if "country" in types:
                            components["country"] = component.get("long_name")
                    
                    return Address(
                        street=components.get("street"),
                        city=components.get("city", ""),
                        state=components.get("state", ""),
                        postal_code=components.get("postal_code"),
                        country=components.get("country", "India"),
                    )
        except Exception as e:
            print(f"Reverse geocoding error: {e}")
        
        return None


class MockGeocoder(GeocodeProvider):
    """Mock geocoder for development."""
    
    async def geocode_address(self, address: Address) -> Optional[GPSCoordinates]:
        """Mock geocoding."""
        print(f"[MOCK GEOCODE] {address.to_string()}")
        # Return center of India
        return GPSCoordinates(latitude=20.5937, longitude=78.9629)
    
    async def reverse_geocode(
        self,
        latitude: float,
        longitude: float,
    ) -> Optional[Address]:
        """Mock reverse geocoding."""
        print(f"[MOCK REVERSE GEOCODE] ({latitude}, {longitude})")
        return Address(
            city="Bangalore",
            state="Karnataka",
            country="India",
        )


# ============================================================================
# Distance Calculation
# ============================================================================

class DistanceCalculator:
    """Calculate distances between GPS coordinates."""
    
    # Earth radius in kilometers
    EARTH_RADIUS_KM = 6371
    
    @staticmethod
    def haversine_distance(
        lat1: float,
        lon1: float,
        lat2: float,
        lon2: float,
    ) -> float:
        """
        Calculate great-circle distance between two points.
        
        Returns:
            Distance in kilometers
        """
        # Convert to radians
        lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
        
        # Haversine formula
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
        c = 2 * asin(sqrt(a))
        
        return DistanceCalculator.EARTH_RADIUS_KM * c
    
    @staticmethod
    def format_distance(distance_km: float) -> str:
        """Format distance for display."""
        if distance_km < 1:
            return f"{distance_km * 1000:.0f}m"
        elif distance_km < 100:
            return f"{distance_km:.1f}km"
        else:
            return f"{distance_km:.0f}km"


# ============================================================================
# Location Service
# ============================================================================

class LocationService:
    """Service for managing locations."""
    
    def __init__(self, geocoder: Optional[GeocodeProvider] = None):
        """Initialize location service."""
        self.geocoder = geocoder or MockGeocoder()
        self.validator = LocationValidator()
    
    async def validate_and_get_location(
        self,
        latitude: float,
        longitude: float,
        accuracy: Optional[float] = None,
        require_address: bool = True,
    ) -> Tuple[bool, Optional[LocationData], Optional[str]]:
        """
        Validate GPS coordinates and optionally get address.
        
        Returns:
            (is_valid, location_data, error_message)
        """
        # Validate coordinates
        is_valid, error = self.validator.validate_for_india(latitude, longitude)
        if not is_valid:
            return False, None, error
        
        # Create initial coordinates
        coordinates = GPSCoordinates(
            latitude=latitude,
            longitude=longitude,
            accuracy=accuracy,
        )
        
        # Get address if required
        if require_address:
            address = await self.geocoder.reverse_geocode(latitude, longitude)
            if not address:
                return False, None, "Could not retrieve address for coordinates"
        else:
            # Placeholder address
            address = Address(
                city="",
                state="",
                country="India",
            )
        
        # Create location data
        accuracy_level = ""
        if accuracy:
            accuracy_level = self.validator.assess_gps_accuracy(accuracy)
        
        location = LocationData(
            coordinates=coordinates,
            address=address,
            source="gps",
            confidence=self._calculate_confidence(accuracy, accuracy_level),
        )
        
        return True, location, None
    
    @staticmethod
    def _calculate_confidence(accuracy: Optional[float], accuracy_level: str) -> float:
        """Calculate confidence score based on accuracy."""
        if not accuracy:
            return 0.5
        
        confidence_map = {
            "excellent": 1.0,
            "good": 0.9,
            "acceptable": 0.7,
            "poor": 0.5,
            "very_poor": 0.2,
        }
        
        return confidence_map.get(accuracy_level, 0.5)
    
    async def geocode_address(
        self,
        city: str,
        state: str,
        country: str = "India",
        street: Optional[str] = None,
        postal_code: Optional[str] = None,
    ) -> Tuple[bool, Optional[LocationData], Optional[str]]:
        """
        Geocode address to GPS coordinates.
        
        Returns:
            (is_valid, location_data, error_message)
        """
        address = Address(
            street=street,
            city=city,
            state=state,
            postal_code=postal_code,
            country=country,
        )
        
        coordinates = await self.geocoder.geocode_address(address)
        if not coordinates:
            return False, None, f"Could not geocode address: {address.to_string()}"
        
        # Validate geocoded coordinates
        is_valid, error = self.validator.validate_for_india(
            coordinates.latitude,
            coordinates.longitude,
        )
        if not is_valid:
            return False, None, error
        
        location = LocationData(
            coordinates=coordinates,
            address=address,
            source="geocoded",
            confidence=0.9,
        )
        
        return True, location, None
    
    async def get_nearby_locations(
        self,
        latitude: float,
        longitude: float,
        locations: List[Tuple[float, float]],
        radius_km: float = 50,
    ) -> List[Tuple[int, float]]:
        """
        Get nearby locations within radius.
        
        Args:
            latitude: Reference latitude
            longitude: Reference longitude
            locations: List of (lat, lon) tuples
            radius_km: Search radius in kilometers
        
        Returns:
            List of (location_index, distance_km) sorted by distance
        """
        nearby = []
        
        for idx, (lat, lon) in enumerate(locations):
            distance = DistanceCalculator.haversine_distance(
                latitude, longitude, lat, lon
            )
            
            if distance <= radius_km:
                nearby.append((idx, distance))
        
        # Sort by distance
        nearby.sort(key=lambda x: x[1])
        
        return nearby


# ============================================================================
# Factory Functions
# ============================================================================

def create_location_service() -> LocationService:
    """Create location service with provider from environment."""
    import os
    
    geocoder = None
    
    # Try Google Maps geocoder
    google_api_key = os.getenv("GOOGLE_MAPS_API_KEY")
    if google_api_key:
        geocoder = GoogleMapsGeocoder(google_api_key)
    else:
        geocoder = MockGeocoder()
    
    return LocationService(geocoder)


# ============================================================================
# Singleton Instance
# ============================================================================

location_service: Optional[LocationService] = None


def get_location_service() -> LocationService:
    """Get or create location service singleton."""
    global location_service
    if location_service is None:
        location_service = create_location_service()
    return location_service

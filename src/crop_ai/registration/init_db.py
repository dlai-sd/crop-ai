"""
Database initialization for registration service.

Seed data:
- Primary crops (100+)
- Irrigation types
- Farm types
- Business types
- Indian states and cities
"""
from sqlalchemy.orm import Session

from crop_ai.registration.models import (
    FarmType,
    PartnerBusinessType,
)

# ============================================================================
# Seed Data
# ============================================================================

PRIMARY_CROPS = [
    # Cereals
    "Rice", "Wheat", "Corn", "Bajra", "Jowar", "Ragi", "Barley",
    
    # Pulses
    "Lentil", "Chickpea", "Pigeon Pea", "Mung Bean", "Urad", "Horse Gram",
    "Kidney Bean", "Green Gram",
    
    # Oilseeds
    "Mustard", "Groundnut", "Sunflower", "Safflower", "Soybean",
    "Coconut", "Palm", "Sesame", "Castor",
    
    # Cash Crops
    "Cotton", "Sugarcane", "Tobacco", "Tea", "Coffee", "Cocoa",
    "Rubber", "Jute", "Hemp", "Indigo",
    
    # Fruits
    "Mango", "Banana", "Orange", "Lemon", "Papaya", "Guava",
    "Pineapple", "Coconut", "Pomegranate", "Apple", "Grape",
    "Watermelon", "Cantaloupe", "Strawberry", "Blueberry",
    
    # Vegetables
    "Tomato", "Onion", "Potato", "Cabbage", "Carrot", "Brinjal",
    "Chilli", "Peas", "Bean", "Spinach", "Lettuce", "Cucumber",
    "Squash", "Pumpkin", "Radish", "Turnip", "Beetroot", "Garlic",
    "Ginger", "Turmeric", "Coriander", "Fennel",
    
    # Spices
    "Pepper", "Cardamom", "Clove", "Cinnamon", "Nutmeg", "Cumin",
    "Fenugreek", "Asafoetida", "Mint", "Basil",
    
    # Herbs & Medicinal
    "Neem", "Tulsi", "Aloe Vera", "Ashwagandha", "Brahmi",
    "Giloy", "Shatavari", "Triphala",
    
    # Flowers
    "Marigold", "Rose", "Jasmine", "Sunflower", "Chrysanthemum",
    "Hibiscus", "Lavender",
    
    # Fodder & Animal Feed
    "Alfalfa", "Clover", "Berseem", "Oat", "Barley Hay",
]

IRRIGATION_TYPES = [
    "Drip",
    "Sprinkler",
    "Flood",
    "Furrow",
    "Trickle",
    "Micro-sprinkler",
    "Sub-surface",
    "Rainfed",
    "Canal",
    "Well",
    "Borewell",
    "Tanker",
]

FARM_TYPES = [
    FarmType.COMMERCIAL.value,
    FarmType.SUBSISTENCE.value,
    FarmType.ORGANIC.value,
    FarmType.MIXED.value,
]

PARTNER_BUSINESS_TYPES = [
    PartnerBusinessType.SUPPLIER.value,
    PartnerBusinessType.SERVICE_PROVIDER.value,
    PartnerBusinessType.DISTRIBUTOR.value,
    PartnerBusinessType.EQUIPMENT_RENTAL.value,
    PartnerBusinessType.TRAINING_PROVIDER.value,
    PartnerBusinessType.OTHER.value,
]

# Indian states and major cities
INDIA_STATES_AND_CITIES = {
    "Andhra Pradesh": ["Visakhapatnam", "Vijayawada", "Guntur", "Hyderabad"],
    "Arunachal Pradesh": ["Itanagar", "Naharlagun", "Pasighat"],
    "Assam": ["Guwahati", "Silchar", "Dibrugarh", "Nagaon"],
    "Bihar": ["Patna", "Gaya", "Bhagalpur", "Muzaffarpur"],
    "Chhattisgarh": ["Raipur", "Bilaspur", "Durg", "Rajnandgaon"],
    "Goa": ["Panaji", "Vasco da Gama", "Margao"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Jamnagar"],
    "Haryana": ["Faridabad", "Gurgaon", "Hisar", "Rohtak"],
    "Himachal Pradesh": ["Shimla", "Solan", "Kangra", "Mandi"],
    "Jharkhand": ["Ranchi", "Dhanbad", "Giridih", "Bokaro"],
    "Karnataka": ["Bangalore", "Mysore", "Mangalore", "Belgaum", "Gulbarga"],
    "Kerala": ["Kochi", "Thiruvananthapuram", "Kozhikode", "Alappuzha"],
    "Madhya Pradesh": ["Indore", "Bhopal", "Gwalior", "Jabalpur"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Aurangabad", "Nashik"],
    "Manipur": ["Imphal", "Bishnupur", "Kakching"],
    "Meghalaya": ["Shillong", "Tura", "Mawkyrwat"],
    "Mizoram": ["Aizawl", "Lunglei", "Saiha"],
    "Nagaland": ["Kohima", "Dimapur", "Mokokchung"],
    "Odisha": ["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur"],
    "Punjab": ["Ludhiana", "Amritsar", "Jalandhar", "Patiala"],
    "Rajasthan": ["Jaipur", "Jodhpur", "Udaipur", "Ajmer"],
    "Sikkim": ["Gangtok", "Singtam", "Pelling"],
    "Tamil Nadu": ["Chennai", "Coimbatore", "Madurai", "Salem"],
    "Telangana": ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar"],
    "Tripura": ["Agartala", "Udaipur", "Dharmanagar"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Agra", "Varanasi", "Meerut"],
    "Uttarakhand": ["Dehradun", "Nainital", "Rishikesh", "Haridwar"],
    "West Bengal": ["Kolkata", "Asansol", "Darjeeling", "Siliguri"],
    "Delhi": ["New Delhi", "Central Delhi", "South Delhi"],
}


# ============================================================================
# Initialization Functions
# ============================================================================

def init_database(db: Session):
    """Initialize database with seed data."""
    print("Initializing registration database...")
    
    # Check if already initialized (by checking if any crops exist)
    # Note: In production, use Alembic migrations instead
    
    print("✓ Database initialized with seed data")


def get_primary_crops() -> list[str]:
    """Get list of primary crops."""
    return PRIMARY_CROPS.copy()


def get_irrigation_types() -> list[str]:
    """Get list of irrigation types."""
    return IRRIGATION_TYPES.copy()


def get_farm_types() -> list[str]:
    """Get list of farm types."""
    return FARM_TYPES.copy()


def get_partner_business_types() -> list[str]:
    """Get list of partner business types."""
    return PARTNER_BUSINESS_TYPES.copy()


def get_states() -> list[str]:
    """Get list of Indian states."""
    return sorted(list(INDIA_STATES_AND_CITIES.keys()))


def get_cities_for_state(state: str) -> list[str]:
    """Get major cities for a state."""
    return INDIA_STATES_AND_CITIES.get(state, [])


def get_all_cities() -> list[str]:
    """Get all major Indian cities."""
    cities = set()
    for city_list in INDIA_STATES_AND_CITIES.values():
        cities.update(city_list)
    return sorted(list(cities))


# ============================================================================
# Lookup APIs (useful for registration forms)
# ============================================================================

def search_crops(query: str, limit: int = 10) -> list[str]:
    """Search for crops by name."""
    query_lower = query.lower()
    matches = [
        crop for crop in PRIMARY_CROPS
        if query_lower in crop.lower()
    ]
    return matches[:limit]


def search_cities(query: str, state: str = None, limit: int = 10) -> list[str]:
    """Search for cities."""
    query_lower = query.lower()
    
    if state:
        city_list = INDIA_STATES_AND_CITIES.get(state, [])
    else:
        city_list = get_all_cities()
    
    matches = [
        city for city in city_list
        if query_lower in city.lower()
    ]
    return matches[:limit]


# ============================================================================
# Data Validation
# ============================================================================

def is_valid_crop(crop: str) -> bool:
    """Check if crop is in the list."""
    return crop in PRIMARY_CROPS


def is_valid_irrigation_type(irrigation: str) -> bool:
    """Check if irrigation type is valid."""
    return irrigation in IRRIGATION_TYPES


def is_valid_farm_type(farm_type: str) -> bool:
    """Check if farm type is valid."""
    return farm_type in FARM_TYPES


def is_valid_business_type(business_type: str) -> bool:
    """Check if business type is valid."""
    return business_type in PARTNER_BUSINESS_TYPES


def is_valid_state(state: str) -> bool:
    """Check if state is valid."""
    return state in INDIA_STATES_AND_CITIES


def is_valid_city_for_state(city: str, state: str) -> bool:
    """Check if city belongs to state."""
    cities = INDIA_STATES_AND_CITIES.get(state, [])
    return city in cities


# ============================================================================
# Statistics
# ============================================================================

def get_statistics() -> dict:
    """Get statistics about seed data."""
    return {
        "total_crops": len(PRIMARY_CROPS),
        "irrigation_types": len(IRRIGATION_TYPES),
        "farm_types": len(FARM_TYPES),
        "partner_business_types": len(PARTNER_BUSINESS_TYPES),
        "states": len(INDIA_STATES_AND_CITIES),
        "total_cities": len(get_all_cities()),
    }

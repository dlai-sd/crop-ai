import 'package:flutter/material.dart';

class CropDataScreen extends StatefulWidget {
  const CropDataScreen({Key? key}) : super(key: key);

  @override
  State<CropDataScreen> createState() => _CropDataScreenState();
}

class _CropDataScreenState extends State<CropDataScreen> {
  final List<String> _activeFilters = ['farmer'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background map (placeholder)
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const NetworkImage(
                'https://images.unsplash.com/photo-1524065607062-1bc6210f2df1?q=80&w=1000&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Top status bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0),
                ],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 15,
              left: 15,
              right: 15,
              bottom: 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📍 Haveli, Pune | 🌤️ 32°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'English',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating pins (farmers, partners, customers)
        Positioned(top: 120, left: 80, child: _buildPin('👨🏽‍🌾', Colors.green, 'Farmer')),
        Positioned(top: 280, left: 180, child: _buildPin('👨🏽‍🌾', Colors.green, 'Farmer')),
        Positioned(top: 200, left: 240, child: _buildPin('🛠️', Colors.blue, 'Partner')),
        Positioned(top: 260, left: 120, child: _buildPin('₹', Colors.amber, 'Customer')),

        // Control deck (chips and inputs)
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              gap: 10,
              children: [
                // Filter chips
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('👨🏽‍🌾 Farmers', 'farmer'),
                      _buildFilterChip('🛠️ Partners', 'partner'),
                      _buildFilterChip('₹ Customers', 'customer'),
                    ],
                  ),
                ),

                // Search input
                _buildFloatingInput('🔍', 'Find Crop (e.g. Wheat)'),

                // Location input
                _buildFloatingInput('📍', 'Go To: Pune, MH'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPin(String emoji, Color color, String label) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tapped: $label')),
      ),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isActive = _activeFilters.contains(type);
    return GestureDetector(
      onTap: () => setState(() {
        if (isActive) {
          _activeFilters.remove(type);
        } else {
          _activeFilters.add(type);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2E7D32) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF444444),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingInput(String icon, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

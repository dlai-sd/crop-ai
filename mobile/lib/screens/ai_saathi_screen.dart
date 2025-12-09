import 'package:flutter/material.dart';

class AISaathiScreen extends StatefulWidget {
  const AISaathiScreen({Key? key}) : super(key: key);

  @override
  State<AISaathiScreen> createState() => _AISaathiScreenState();
}

class _AISaathiScreenState extends State<AISaathiScreen> {
  String? _selectedCrop;
  bool _showResult = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background map
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
            child: const Text(
              '🧠 AI Advisor Mode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // AI Card docked above nav
        Positioned(
          bottom: 90,
          left: 15,
          right: 15,
          child: _buildAICard(),
        ),
      ],
    );
  }

  Widget _buildAICard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6200EA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'AI Crop Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Satellite Analysis',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a crop to check viability:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                ),
                const SizedBox(height: 15),

                // Crop selector and GO button
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCrop,
                        hint: const Text('Select Crop...'),
                        items: const [
                          DropdownMenuItem(value: 'onion', child: Text('Onion (Kanda)')),
                          DropdownMenuItem(value: 'wheat', child: Text('Wheat (Gehu)')),
                        ],
                        onChanged: (value) => setState(() => _selectedCrop = value),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedCrop != null) {
                          setState(() => _showResult = !_showResult);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'GO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Results
                if (_showResult) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠️ HIGH RISK DETECTED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildMetricRow('🚜 Saturation (Neighbors)', '85%', const Color(0xFFD32F2F)),
                  const SizedBox(height: 12),
                  _buildMetricRow('📉 Market Price', 'Falling', const Color(0xFFD32F2F)),
                  const SizedBox(height: 12),
                  _buildMetricRow('🌤️ Weather', 'Favorable', const Color(0xFF2E7D32)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Text('💡', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tip: Consider Garlic instead.',
                            style: TextStyle(
                              color: Color(0xFF4A148C),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

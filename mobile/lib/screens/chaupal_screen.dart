import 'package:flutter/material.dart';

class ChauphalScreen extends StatefulWidget {
  const ChauphalScreen({Key? key}) : super(key: key);

  @override
  State<ChauphalScreen> createState() => _ChauphalScreenState();
}

class _ChauphalScreenState extends State<ChauphalScreen> {
  final List<String> _activeFilters = ['All Updates'];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Chaupal',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('🔔', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),

        // Broadcast box
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: Row(
                    children: [
                      const Text('📢', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'Broadcast Update...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const Text('📷', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Filter chips
                SizedBox(
                  height: 35,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All Updates'),
                      _buildFilterChip('🚜 Equipment'),
                      _buildFilterChip('🌾 Crops'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Feed cards
        SliverList(
          delegate: SliverChildListDelegate([
            _buildFeedCard(
              avatar: '🛠️',
              avatarBg: const Color(0xFFE3F2FD),
              avatarColor: const Color(0xFF1565C0),
              name: 'Shiva Tools',
              badge: 'Partner',
              badgeBg: const Color(0xFFE3F2FD),
              badgeColor: const Color(0xFF1565C0),
              time: '20 mins ago',
              content: 'New Harvester available for rent!',
            ),
            _buildFeedCard(
              avatar: '₹',
              avatarBg: const Color(0xFFFFF8E1),
              avatarColor: const Color(0xFFF57F17),
              name: 'Mandi Agent',
              badge: 'Buyer',
              badgeBg: const Color(0xFFFFF8E1),
              badgeColor: const Color(0xFFF57F17),
              time: '2 hrs ago',
              content: 'Buying Wheat (Sharbati) at ₹2200/quintal. Spot Cash payment.',
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _activeFilters.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        _activeFilters.clear();
        _activeFilters.add(label);
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF555555),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard({
    required String avatar,
    required Color avatarBg,
    required Color avatarColor,
    required String name,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String time,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarBg,
                  ),
                  child: Center(
                    child: Text(
                      avatar,
                      style: TextStyle(fontSize: 20, color: avatarColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),

            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Text('📞'),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F5E9),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Text('💬'),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3F2FD),
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

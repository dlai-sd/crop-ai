import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('My Account'),
          elevation: 0,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Profile Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D7377),
                      Color(0xFF14919B),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Text('👨🏽‍🌾', style: TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rajesh Kumar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Level 5 Farmer',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('450', 'Trust\nPoints'),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    _buildStat('12', 'Broadcasts'),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey[300],
                    ),
                    _buildStat('8', 'Network'),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1),

              // Menu Items
              _buildMenuItem(
                'My Farms',
                'Manage your farms',
                Icons.agriculture,
              ),
              _buildMenuItem(
                'Order History',
                'View past orders',
                Icons.history,
              ),
              _buildMenuItem(
                'Payments',
                'Billing & transactions',
                Icons.payment,
              ),
              _buildMenuItem(
                'Settings',
                'App preferences',
                Icons.settings,
              ),
              _buildMenuItem(
                'Help & Support',
                'Get help or report issues',
                Icons.help,
              ),
              _buildMenuItem(
                'About',
                'App version 2.0',
                Icons.info,
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {},
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D7377),
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D7377)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

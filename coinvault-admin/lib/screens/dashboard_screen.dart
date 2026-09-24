import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'users_screen.dart';
import 'offers_screen.dart';
import 'payouts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _selectedIndex = 0;

  final List<_ScreenConfig> _screens = [
    _ScreenConfig('Dashboard', Icons.dashboard, _buildDashboard),
    _ScreenConfig('Users', Icons.people, _buildUsers),
    _ScreenConfig('Offers', Icons.card_giftcard, _buildOffers),
    _ScreenConfig('Payouts', Icons.account_balance_wallet, _buildPayouts),
    _ScreenConfig('Settings', Icons.settings, _buildSettings),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await ApiService.get('/api/admin-v2/stats');
    if (mounted) {
      setState(() {
        _stats = data?['data'];
        _isLoading = false;
      });
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final items = <_StatItem>[];

    if (_stats != null) {
      if (_stats!['users'] != null) {
        items.add(_StatItem(
          'Total Users',
          _stats!['users'].toString(),
          Icons.people,
          Colors.blue,
        ));
      }
      if (_stats!['activeToday'] != null) {
        items.add(_StatItem(
          'Active Today',
          _stats!['activeToday'].toString(),
          Icons.touch_app,
          Colors.green,
        ));
      }
      if (_stats!['pendingWithdrawals'] != null) {
        items.add(_StatItem(
          'Pending Payouts',
          _stats!['pendingWithdrawals'].toString(),
          Icons.hourglass_bottom,
          Colors.orange,
        ));
      }
      if (_stats!['coinsIssued'] != null) {
        final coins = _stats!['coinsIssued'];
        items.add(_StatItem(
          'Coins Issued',
          coins.toString(),
          Icons.monetization_on,
          Colors.purple,
        ));
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _StatCard(item: items[index]),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('Manage Users'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.green),
              title: const Text('Manage Offers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
              title: const Text('Review Payouts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsers() => const UsersScreen();
  Widget _buildOffers() => const OffersScreen();
  Widget _buildPayouts() => const PayoutsScreen();

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await ApiService.clearToken();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_screens[_selectedIndex].title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedIndex == 0 ? _loadStats : null,
          ),
        ],
      ),
      body: _screens[_selectedIndex].builder(),
    );
  }
}

class _ScreenConfig {
  final String title;
  final IconData icon;
  final Widget Function() builder;

  _ScreenConfig(this.title, this.icon, this.builder);
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const Spacer(),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

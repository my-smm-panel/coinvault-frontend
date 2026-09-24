import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  int _totalUsers = 0;
  bool _isLoading = true;
  int _offset = 0;
  const int _limit = 30;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final searchPart = _searchQuery.isNotEmpty ? '?q=$_searchQuery' : '';
    final data = await ApiService.get('/api/admin-v2/users?limit=$_limit&offset=$_offset$searchPart');

    if (mounted) {
      setState(() {
        _users = data?['data']?['items'] ?? [];
        _totalUsers = data?['data']?['total'] ?? 0;
        _isLoading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query;
      _offset = 0;
    });
    _loadUsers();
  }

  Future<void> _banUser(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: const Text('Are you sure you want to ban this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ban'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.put(
        '/api/admin-v2/users/${user['id']}/ban',
        {'reason': 'Violated terms of service'},
      );

      if (result != null && result['success'] == true) {
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == user['id']);
          if (index != -1) {
            _users[index] = {...user, 'isBanned': true, 'banReason': 'Violated terms of service'};
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User banned')));
      }
    }
  }

  Future<void> _unbanUser(dynamic user) async {
    final result = await ApiService.put(
      '/api/admin-v2/users/${user['id']}/unban',
      {},
    );

    if (result != null && result['success'] == true) {
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == user['id']);
        if (index != -1) {
          _users[index] = {...user, 'isBanned': false, 'banReason': null};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unbanned')));
    }
  }

  Future<void> _loadMore() async {
    if (_users.length >= _totalUsers) return;

    final data = await ApiService.get('/api/admin-v2/users?limit=$_limit&offset=${_offset + _limit}');

    if (data != null) {
      final newUsers = data['data']['items'] as List;
      setState(() {
        _users.addAll(newUsers);
        _offset += _limit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, email, phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _search,
          ),
        ),
        Expanded(
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _users.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      if (_users.length >= _totalUsers) {
                        return const SizedBox();
                      }
                      return ListTile(
                        title: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final user = _users[index];
                    return _UserTile(user: user, onBan: _banUser, onUnban: _unbanUser);
                  },
                ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final dynamic user;
  final Function(dynamic) onBan;
  final Function(dynamic) onUnban;

  const _UserTile({required this.user, required this.onBan, required this.onUnban});

  @override
  Widget build(BuildContext context) {
    final isBanned = user['isBanned'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(user['name']?[0] ?? '?', style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user['name'] ?? 'No name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isBanned)
                            Container(
                              margin: const EdgeInsets.left(8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('BANNED', style: TextStyle(fontSize: 10, color: Colors.red)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        user['phone'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isBanned)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.green),
                    onPressed: () => onUnban(user),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.block, color: Colors.red),
                    onPressed: () => onBan(user),
                  ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip('Coins: ${user['coins'] ?? 0}'),
                _InfoChip('Earned: ${user['totalEarned'] ?? 0}'),
                _InfoChip('Withd: ${user['totalWithdrawn'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;

  const _InfoChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

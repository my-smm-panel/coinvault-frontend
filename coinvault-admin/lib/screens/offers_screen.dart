import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final data = await ApiService.get('/api/admin-v2/offers');

    if (mounted) {
      setState(() {
        _offers = data?['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOffer(dynamic offer) async {
    final newState = offer['isActive'] == true ? false : true;
    final result = await ApiService.put(
      '/api/admin-v2/offers/${offer['id']}',
      {'isActive': newState},
    );

    if (result != null && result['success'] == true) {
      setState(() {
        final index = _offers.indexWhere((o) => o['id'] == offer['id']);
        if (index != -1) {
          _offers[index] = {...offer, 'isActive': newState};
        }
      });
    }
  }

  Future<void> _deleteOffer(dynamic offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Delete "${offer['name'] ?? 'this offer'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.delete('/api/admin-v2/offers/${offer['id']}');

      if (result != null && result['success'] == true) {
        setState(() {
          _offers.removeWhere((o) => o['id'] == offer['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search offers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _offers.isEmpty
                  ? const Center(child: Text('No offers found'))
                  : ListView.builder(
                      itemCount: _offers.length,
                      itemBuilder: (context, index) => _OfferTile(
                        offer: _offers[index],
                        onToggle: _toggleOffer,
                        onDelete: _deleteOffer,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _OfferTile extends StatelessWidget {
  final dynamic offer;
  final Function(dynamic) onToggle;
  final Function(dynamic) onDelete;

  const _OfferTile({required this.offer, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isActive = offer['isActive'] == true;
    final type = offer['type'] ?? 'unknown';
    final reward = offer['reward'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.check_circle : Icons.block,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer['name'] ?? type, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Reward: $reward coins • $type',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Text(
          'Provider: ${offer['provider'] ?? 'N/A'}',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Disable' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'toggle') {
              onToggle(offer);
            } else if (value == 'delete') {
              onDelete(offer);
            }
          },
        ),
      ),
    );
  }
}

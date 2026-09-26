import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/app_repository.dart';
import '../widgets/state_views.dart';

/// Notifications inbox (kit screen 13).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final items = await AppRepository.instance.notificationsList();
    if (!mounted) return;
    setState(() {
      _items = items ?? [];
      _failed = items == null;
      _loading = false;
    });
  }

  Future<void> _open(Map m) async {
    final id = (m['id'] ?? '').toString();
    if (id.isNotEmpty && m['isRead'] != true) {
      final updated = await AppRepository.instance.notifRead(id);
      if (updated && mounted) {
        setState(() {
          final i = _items.indexWhere((e) => (e as Map)['id'] == id);
          if (i >= 0) {
            final copy = Map<String, dynamic>.from(_items[i] as Map);
            copy['isRead'] = true;
            _items[i] = copy;
          }
        });
      }
    }
  }

  Future<void> _readAll() async {
    if (_loading || _failed || !_items.any((item) => item is Map && item['isRead'] != true)) {
      return;
    }
    final updated = await AppRepository.instance.notifReadAll();
    if (updated) {
      await _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update notifications right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _loading ||
                    _failed ||
                    !_items.any((item) => item is Map && item['isRead'] != true)
                ? null
                : _readAll,
            child: const Text('Mark all read', 
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _loading
          ? const ShimmerCardList(rows: 5)
          : _failed
              ? ErrorState(
                  message: 'Notifications could not be fetched. Try again.',
                  onRetry: _load,
                )
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final m =
                              Map<String, dynamic>.from(_items[i] as Map);
                          final unread = m['isRead'] != true;
                          return InkWell(
                            onTap: () => _open(m),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: unread
                                    ? AppColors.primaryContainer
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: unread
                                      ? AppColors.primary.withOpacity(0.3)
                                      : AppColors.divider,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: unread
                                          ? AppColors.primary.withOpacity(0.15)
                                          : AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_rounded,
                                      size: 20,
                                      color: unread
                                          ? AppColors.primary
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (m['title'] ?? 'Notification')
                                              .toString(),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (m['message'] ?? '').toString(),
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

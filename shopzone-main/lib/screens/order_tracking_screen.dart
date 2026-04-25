import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _orders = await ApiService.getOrders();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'shipped': return Colors.purple;
      case 'out_for_delivery': return Colors.teal;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.accent;
      default: return AppColors.textSecondary(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No orders yet', style: TextStyle(color: AppColors.textSecondary(context))),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (_, i) {
            final o = _orders[i];
            final items = o['items'] as List? ?? [];
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o['id']))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Order #${o['id'].toString().substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(o['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (o['status'] ?? 'pending').toString().replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: _statusColor(o['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(o['created_at']?.toString().substring(0, 10) ?? '',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                    const Divider(height: 20),
                    ...items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item['product_name']}',
                              style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('x${item['quantity']}', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                        ],
                      ),
                    )),
                    if (items.length > 3)
                      Text('+${items.length - 3} more items',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('\$${double.parse(o['total'].toString()).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    if (o['latest_tracking'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text(o['latest_tracking'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                        ],
                      ),
                    ],
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

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  List<dynamic> _tracking = [];
  bool _loading = true;

  final _allStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getOrderTracking(widget.orderId);
      _order = data['order'];
      _tracking = data['tracking'];
    } catch (_) {}
    setState(() => _loading = false);
  }

  int get _currentStep {
    if (_order == null) return 0;
    final idx = _allStatuses.indexOf(_order!['status'] ?? 'pending');
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${widget.orderId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (_order?['tracking_number'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: AppColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text('Tracking: ${_order!['tracking_number']}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (_order?['estimated_delivery'] != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text('Est. delivery: ${_order!['estimated_delivery'].toString().substring(0, 10)}',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                ...List.generate(_allStatuses.length, (i) {
                  final isCompleted = i <= _currentStep;
                  final isCurrent = i == _currentStep;
                  final isLast = i == _allStatuses.length - 1;
                  final statusLabel = _allStatuses[i].replaceAll('_', ' ');

                  final trackingEntry = _tracking.cast<Map<String, dynamic>?>().firstWhere(
                        (t) => t?['status'] == _allStatuses[i], orElse: () => null,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted ? AppColors.accent : Colors.grey[200],
                              border: isCurrent ? Border.all(color: AppColors.accent, width: 3) : null,
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          if (!isLast) Container(
                            width: 2, height: 40,
                            color: isCompleted ? AppColors.accent : Colors.grey[200],
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(statusLabel[0].toUpperCase() + statusLabel.substring(1),
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCompleted ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                                    fontSize: isCurrent ? 15 : 14,
                                  )),
                              if (trackingEntry != null) ...[
                                const SizedBox(height: 2),
                                Text(trackingEntry['description'] ?? '',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                                Text(trackingEntry['created_at']?.toString().substring(0, 16) ?? '',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...(_order?['items'] as List? ?? []).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(item['product_name'] ?? '', style: const TextStyle(fontSize: 14))),
                      Text('x${item['quantity']}', style: TextStyle(color: AppColors.textSecondary(context))),
                      const SizedBox(width: 12),
                      Text('\$${double.parse(item['unit_price'].toString()).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
                const Divider(height: 20),
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Spacer(),
                    Text('\$${double.parse((_order?['total'] ?? 0).toString()).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
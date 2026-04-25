import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'addresses_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, dynamic>? _selectedAddress;
  String _paymentMethod = 'card';
  bool _processing = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final addresses = await ApiService.getAddresses();
      if (addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = addresses.firstWhere(
                (a) => a['is_default'] == true,
            orElse: () => addresses.first,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a delivery address')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final order = await ApiService.placeOrder(_selectedAddress!['id'], _paymentMethod);
      final orderId = order['id'];

      if (_paymentMethod == 'card') {
        final clientSecret = await ApiService.createPaymentIntent(orderId);
      }

      if (mounted) {
        context.read<CartProvider>().loadCart();
        _showSuccessDialog(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    setState(() => _processing = false);
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.1),
              ),
              child: const Icon(Icons.check_circle, size: 56, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text('Order Placed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Order #${orderId.substring(0, 8)}',
                style: TextStyle(color: AppColors.textSecondary(context))),
            const SizedBox(height: 6),
            Text('Thank you for your purchase!',
                style: TextStyle(color: AppColors.textSecondary(context)), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)));
            },
            child: const Text('Track Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _placeOrder();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) setState(() => _currentStep--);
              },
              controlsBuilder: (ctx, details) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? 'Place Order' : 'Continue'),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                    ],
                  ],
                ),
              ),
              steps: [
                Step(
                  title: const Text('Delivery Address'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      if (_selectedAddress != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.accent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(_selectedAddress!['label'] ?? 'Address',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  const Icon(Icons.check_circle, size: 18, color: AppColors.accent),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(_selectedAddress!['address_line1'] ?? ''),
                              Text('${_selectedAddress!['city']}, ${_selectedAddress!['country']}'),
                            ],
                          ),
                        )
                      else
                        Text('No address selected', style: TextStyle(color: AppColors.textSecondary(context))),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final addr = await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const AddressesScreen(selectMode: true)));
                          if (addr != null) setState(() => _selectedAddress = addr);
                        },
                        icon: const Icon(Icons.location_on_outlined),
                        label: Text(_selectedAddress != null ? 'Change Address' : 'Add Address'),
                      ),
                    ],
                  ),
                ),

                Step(
                  title: const Text('Payment'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      _PaymentOption(
                        icon: Icons.credit_card,
                        title: 'Credit/Debit Card',
                        subtitle: 'Pay securely with Stripe',
                        selected: _paymentMethod == 'card',
                        onTap: () => setState(() => _paymentMethod = 'card'),
                      ),
                      const SizedBox(height: 10),
                      _PaymentOption(
                        icon: Icons.money,
                        title: 'Cash on Delivery',
                        subtitle: 'Pay when you receive',
                        selected: _paymentMethod == 'cod',
                        onTap: () => setState(() => _paymentMethod = 'cod'),
                      ),
                    ],
                  ),
                ),

                Step(
                  title: const Text('Review Order'),
                  isActive: _currentStep >= 2,
                  content: Column(
                    children: [
                      ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('x${item.quantity}', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                            const SizedBox(width: 12),
                            Text('\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      )),
                      const Divider(height: 20),
                      _SummaryLine('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                      _SummaryLine('Shipping', cart.shipping == 0 ? 'Free' : '\$${cart.shipping.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      _SummaryLine('Total', '\$${cart.total.toStringAsFixed(2)}', bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_processing)
            const LinearProgressIndicator(color: AppColors.accent),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon, required this.title, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.accent : Colors.grey[300]!, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummaryLine(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: bold ? 16 : 14,
          )),
          Text(value, style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: bold ? 16 : 14,
            color: bold ? AppColors.accent : null,
          )),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AddressesScreen extends StatefulWidget {
  final bool selectMode;
  const AddressesScreen({super.key, this.selectMode = false});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<dynamic> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _addresses = await ApiService.getAddresses();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.selectMode ? 'Select Address' : 'My Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressForm(context),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No addresses yet', style: TextStyle(color: AppColors.textSecondary(context))),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _addresses.length,
        itemBuilder: (_, i) {
          final a = _addresses[i];
          return GestureDetector(
            onTap: widget.selectMode ? () => Navigator.pop(context, a) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: a['is_default'] == true
                    ? Border.all(color: AppColors.accent, width: 2)
                    : null,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(a['label'] ?? 'Address',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                      if (a['is_default'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Default', style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ),
                      ],
                      const Spacer(),
                      if (!widget.selectMode) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddressForm(context, address: a),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.accent),
                          onPressed: () async {
                            await ApiService.deleteAddress(a['id']);
                            _load();
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (a['full_name'] != null)
                    Text(a['full_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(a['address_line1'] ?? '', style: const TextStyle(height: 1.5)),
                  if (a['address_line2'] != null && a['address_line2'].toString().isNotEmpty)
                    Text(a['address_line2']),
                  Text('${a['city'] ?? ''}, ${a['state'] ?? ''} ${a['zip_code'] ?? ''}'),
                  Text(a['country'] ?? '', style: TextStyle(color: AppColors.textSecondary(context))),
                  if (a['phone'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppColors.textSecondary(context)),
                        const SizedBox(width: 4),
                        Text(a['phone'], style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                      ],
                    ),
                  ],
                  if (!widget.selectMode && a['is_default'] != true) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        await ApiService.setDefaultAddress(a['id']);
                        _load();
                      },
                      child: const Text('Set as Default', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddressForm(BuildContext context, {Map<String, dynamic>? address}) {
    final isEdit = address != null;
    final labelCtrl = TextEditingController(text: address?['label'] ?? 'Home');
    final nameCtrl = TextEditingController(text: address?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: address?['phone'] ?? '');
    final line1Ctrl = TextEditingController(text: address?['address_line1'] ?? '');
    final line2Ctrl = TextEditingController(text: address?['address_line2'] ?? '');
    final cityCtrl = TextEditingController(text: address?['city'] ?? '');
    final stateCtrl = TextEditingController(text: address?['state'] ?? '');
    final zipCtrl = TextEditingController(text: address?['zip_code'] ?? '');
    final countryCtrl = TextEditingController(text: address?['country'] ?? '');
    bool isDefault = address?['is_default'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Address' : 'New Address',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _FormField(ctrl: labelCtrl, label: 'Label (Home, Work, etc.)'),
                _FormField(ctrl: nameCtrl, label: 'Full Name'),
                _FormField(ctrl: phoneCtrl, label: 'Phone', type: TextInputType.phone),
                _FormField(ctrl: line1Ctrl, label: 'Address Line 1'),
                _FormField(ctrl: line2Ctrl, label: 'Address Line 2 (optional)'),
                Row(children: [
                  Expanded(child: _FormField(ctrl: cityCtrl, label: 'City')),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(ctrl: stateCtrl, label: 'State')),
                ]),
                Row(children: [
                  Expanded(child: _FormField(ctrl: zipCtrl, label: 'ZIP Code')),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(ctrl: countryCtrl, label: 'Country')),
                ]),
                CheckboxListTile(
                  value: isDefault,
                  onChanged: (v) => setSheetState(() => isDefault = v ?? false),
                  title: const Text('Set as default address', style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final data = {
                        'label': labelCtrl.text, 'full_name': nameCtrl.text,
                        'phone': phoneCtrl.text, 'address_line1': line1Ctrl.text,
                        'address_line2': line2Ctrl.text, 'city': cityCtrl.text,
                        'state': stateCtrl.text, 'zip_code': zipCtrl.text,
                        'country': countryCtrl.text, 'is_default': isDefault,
                      };
                      if (isEdit) {
                        await ApiService.updateAddress(address!['id'], data);
                      } else {
                        await ApiService.addAddress(data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    },
                    child: Text(isEdit ? 'Update' : 'Save Address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? type;
  const _FormField({required this.ctrl, required this.label, this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
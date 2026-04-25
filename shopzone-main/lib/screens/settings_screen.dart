import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'addresses_screen.dart';
import 'order_tracking_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 30, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          )),
                      const SizedBox(height: 2),
                      Text('Manage your account',
                          style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary(context)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle('Appearance', context),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: SwitchListTile(
              title: Text('Dark Mode',
                  style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)),
              subtitle: Text(theme.isDark ? 'Dark theme active' : 'Light theme active',
                  style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
              secondary: Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.accent,
              ),
              value: theme.isDark,
              activeColor: AppColors.accent,
              onChanged: (_) => theme.toggle(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle('Account', context),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'My Addresses',
                  context: context,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddressesScreen())),
                ),
                Divider(height: 1, color: AppColors.border(context)),
                _SettingsTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order History',
                  context: context,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const OrdersListScreen())),
                ),
                Divider(height: 1, color: AppColors.border(context)),
                _SettingsTile(
                  icon: Icons.favorite_border,
                  title: 'Wishlist',
                  context: context,
                  onTap: () {},
                ),
                Divider(height: 1, color: AppColors.border(context)),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  context: context,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle('About', context),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                _SettingsTile(icon: Icons.info_outline, title: 'About ShopZone', context: context, onTap: () {}),
                Divider(height: 1, color: AppColors.border(context)),
                _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', context: context, onTap: () {}),
                Divider(height: 1, color: AppColors.border(context)),
                _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', context: context, onTap: () {}),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.accent),
              label: const Text('Log Out', style: TextStyle(color: AppColors.accent)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Text('ShopZone v2.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final BuildContext ctx;
  const _SectionTitle(this.title, this.ctx);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(ctx),
            letterSpacing: 0.5,
          )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final BuildContext context;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.context,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 22),
      title: Text(title,
          style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary(context)),
      onTap: onTap,
    );
  }
}
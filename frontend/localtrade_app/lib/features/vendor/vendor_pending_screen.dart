import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class VendorPendingScreen extends StatelessWidget {
  const VendorPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final status = user?['vendorApprovalStatus'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Status'),
        actions: [
          IconButton(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'suspended' ? Icons.block_flipped : Icons.hourglass_top_rounded,
                  size: 80,
                  color: status == 'suspended' ? Colors.red : AppTheme.secondaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  status == 'suspended' ? 'Account Suspended' : 'Approval Pending',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  status == 'suspended' 
                    ? 'Your account has been suspended by the administrator. Please contact support for more information.'
                    : 'Your vendor account is currently being reviewed by our team. You will be notified once it is approved.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Logout'),
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

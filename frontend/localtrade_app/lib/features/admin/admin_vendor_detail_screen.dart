import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/admin_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/skeleton_loaders.dart';

class AdminVendorDetailScreen extends StatefulWidget {
  final String vendorId;

  const AdminVendorDetailScreen({super.key, required this.vendorId});

  @override
  State<AdminVendorDetailScreen> createState() => _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState extends State<AdminVendorDetailScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _vendor;
  Map<String, dynamic>? _stats;
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  Future<void> _loadVendor() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _adminService.getVendorDetail(widget.vendorId);
      setState(() {
        _vendor = result['data']['vendor'];
        _stats = result['data']['stats'];
        _recentOrders = result['data']['recentOrders'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_vendor?['shopName'] ?? _vendor?['fullName'] ?? 'Vendor details', style: AppTextStyles.sectionHeading),
        centerTitle: false,
      ),
      body: _isLoading
          ? const ProductDetailSkeleton()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodyMuted),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadVendor, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final vendor = _vendor!;
    final stats = _stats!;
    final status = vendor['vendorApprovalStatus'] ?? 'pending';
    final createdAt = vendor['createdAt'];
    final address = vendor['address'];
    final categories = (vendor['categories'] as List?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor header card
          _buildCard(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.coralLight, shape: BoxShape.circle),
                    child: const Icon(Icons.storefront_rounded, size: 24, color: AppColors.coralDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor['shopName'] ?? vendor['fullName'] ?? '', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(vendor['email'] ?? '', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(Icons.shopping_bag_outlined, '${stats['totalProducts'] ?? 0}', 'Products', AppColors.coralLight)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(Icons.receipt_long_outlined, '${stats['totalOrders'] ?? 0}', 'Orders', const Color(0xFFE8F5E9))),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(Icons.check_circle_outline, '${stats['deliveredOrders'] ?? 0}', 'Delivered', const Color(0xFFE3F2FD))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(Icons.schedule, '${stats['pendingOrders'] ?? 0}', 'Pending', AppColors.warningLight)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(Icons.cancel_outlined, '${stats['cancelledOrders'] ?? 0}', 'Cancelled', AppColors.mutedLight)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(Icons.payments_outlined, 'Rs. ${stats['totalRevenue'] ?? 0}', 'Revenue', AppColors.coralLight)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact & details card
          _buildCard(
            children: [
              if (vendor['phone'] != null) ...[
                _buildDetailRow(Icons.phone_outlined, 'Phone', vendor['phone']),
                const SizedBox(height: 8),
              ],
              if (vendor['businessDescription'] != null && (vendor['businessDescription'] as String).isNotEmpty) ...[
                _buildDetailRow(Icons.info_outline, 'About', vendor['businessDescription']),
                const SizedBox(height: 8),
              ],
              if (vendor['openingHours'] != null) ...[
                _buildDetailRow(Icons.access_time_rounded, 'Hours', vendor['openingHours']),
                const SizedBox(height: 8),
              ],
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categories.map<Widget>((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coralLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(c.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.coralDark)),
                  )).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Address card
          if (address != null) ...[
            _buildCard(
              children: [
                _buildDetailRow(Icons.home_outlined, 'Address', _formatAddress(address)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Recent orders
          if (_recentOrders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
              child: Text('Recent orders', style: AppTextStyles.sectionHeading),
            ),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                ..._recentOrders.map((order) {
                  final customerName = order['customerId']?['fullName'] ?? 'Customer';
                  final total = order['totalAmount'] ?? 0;
                  final status = order['orderStatus'] ?? 'Pending';
                  final dateStr = order['createdAt'];
                  String dateLabel = '';
                  if (dateStr != null) {
                    try {
                      dateLabel = DateFormat('MMM d').format(DateTime.parse(dateStr).toLocal());
                    } catch (_) {}
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customerName, style: AppTextStyles.label),
                              const SizedBox(height: 2),
                              Text(dateLabel, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        Text('Rs. $total', style: AppTextStyles.label),
                        const SizedBox(width: 8),
                        _buildStatusChip(status),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Timestamps
          _buildCard(
            children: [
              if (createdAt != null) _buildDetailRow(Icons.access_time_rounded, 'Joined', _formatDate(createdAt)),
              if (createdAt != null && vendor['updatedAt'] != null) const SizedBox(height: 6),
              if (vendor['updatedAt'] != null) _buildDetailRow(Icons.update_rounded, 'Updated', _formatDate(vendor['updatedAt'])),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPaddingH),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D2B2620), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.ink.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: AppColors.muted.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'approved':
        bgColor = AppColors.successLight;
        textColor = AppColors.successDark;
        label = 'Approved';
        break;
      case 'pending':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningDark;
        label = 'Pending';
        break;
      case 'suspended':
        bgColor = AppColors.mutedLight;
        textColor = AppColors.muted;
        label = 'Suspended';
        break;
      default:
        bgColor = AppColors.mutedLight;
        textColor = AppColors.muted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status == 'approved' ? Icons.check_circle_outline : (status == 'pending' ? Icons.schedule : Icons.pause_circle_outline), size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textColor)),
        ],
      ),
    );
  }

  String _formatAddress(dynamic addr) {
    if (addr == null) return '';
    if (addr is String) return addr;
    if (addr is Map) {
      final parts = [addr['street'], addr['city'], addr['state'], addr['zipCode']].where((e) => e != null && e.toString().isNotEmpty).map((e) => e.toString());
      return parts.join(', ');
    }
    return addr.toString();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays < 1) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 30) return '${diff.inDays} days ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
      return '${(diff.inDays / 365).floor()} years ago';
    } catch (_) {
      return dateStr;
    }
  }
}

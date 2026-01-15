import 'package:flutter/material.dart';
import '../../../core/common/constants.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';

class TenantHomeCard extends StatelessWidget {
  final TenantModel? tenantData;
  final PropertyModel? propertyData;
  final bool isLoading;
  final String? unitNumberOverride;

  const TenantHomeCard({
    super.key,
    required this.tenantData,
    required this.propertyData,
    required this.isLoading,
    this.unitNumberOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200, // Taller skeleton
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (tenantData == null) {
      return const SizedBox.shrink();
    }

    final propertyName = tenantData?.propertyName ?? propertyData?.title ?? 'My Home';
    String? displayUnit = unitNumberOverride;
    if (displayUnit == null && tenantData?.unitNumber != null && tenantData!.unitNumber.isNotEmpty) {
      displayUnit = tenantData!.unitNumber;
    }

    final propertyAddress = propertyData?.address.fullAddress ?? 'Address loading...';
    // Use first image or a placeholder
    final propertyImage = (propertyData?.images != null && propertyData!.images.isNotEmpty)
        ? propertyData!.images.first
        : 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?q=80&w=1000&auto=format&fit=crop';

    final managerName = propertyData?.ownerName.isNotEmpty == true 
        ? propertyData!.ownerName 
        : 'Property Manager';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235), // Dark card background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  propertyImage,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.home, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Active Lease',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayUnit != null ? '$propertyName, Unit $displayUnit' : propertyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  propertyAddress,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.business, color: Colors.blue.shade700, size: 20), // Placeholder logo icon
                    const SizedBox(width: 8),
                    Text(
                      'Managed by $managerName', 
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
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

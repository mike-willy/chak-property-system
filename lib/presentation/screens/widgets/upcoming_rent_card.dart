import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart'; // Add this import
import '../../../data/models/address_model.dart'; // Add this import

import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/address_model.dart';

class UpcomingRentCard extends StatelessWidget {
  final TenantModel? tenantData;
  final bool isLoading;
  final List<PropertyModel> properties;

  const UpcomingRentCard({
    super.key,
    required this.tenantData,
    required this.isLoading,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 180,
        width: double.infinity,
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

    // 1. Try to use rent from TenantModel if available
    double rentAmount = tenantData!.rentAmount;
    
    // 2. If 0, fetch from linked Property
    if (rentAmount == 0) {
       final property = properties.firstWhere(
        (p) => p.id == tenantData!.propertyId || p.unitId == tenantData!.unitId,
        orElse: () => PropertyModel(
          id: '',
          title: '',
          unitId: '',
          description: '',
          address: AddressModel(street: '', city: '', state: '', zipCode: ''),
          ownerId: '',
          ownerName: '',
          price: 0,
          deposit: 0,
          bedrooms: 0,
          bathrooms: 0,
          squareFeet: 0,
          amenities: [],
          images: [],
          status: PropertyStatus.vacant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      rentAmount = property.price;
    }

    // Calculate next rent date
    final nextRentDate = tenantData!.leaseStartDate?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30));
    final daysRemaining = nextRentDate.difference(DateTime.now()).inDays;
    final isDueSoon = daysRemaining <= 5;

    // Format currency (simple KES)
    final amount = rentAmount.toStringAsFixed(2); // e.g. "1200.00"

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
         color: const Color(0xFF1E2235), // Dark card background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEXT RENT DUE',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              if (isDueSoon)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'KES $amount',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Colors.orange.shade400, size: 16),
              const SizedBox(width: 6),
              Text(
                'Due in $daysRemaining Days (${nextRentDate.month}/${nextRentDate.day})',
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment integration coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.payment, size: 20),
                       SizedBox(width: 8),
                       Text(
                        'Pay Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Secure payment via Stripe',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

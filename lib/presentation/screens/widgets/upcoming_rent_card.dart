import 'package:flutter/material.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/address_model.dart';
// Make sure this import path is correct
import '../../screens/payments/payment_page.dart';

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
    PropertyModel? property;
    if (rentAmount == 0) {
      property = properties.firstWhere(
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
    } else {
      // If rent amount exists, still try to get property details
      property = properties.firstWhere(
        (p) => p.id == tenantData!.propertyId || p.unitId == tenantData!.unitId,
        orElse: () => PropertyModel(
          id: '',
          title: 'Your Unit',
          unitId: tenantData!.unitId,
          description: '',
          address: AddressModel(street: '', city: '', state: '', zipCode: ''),
          ownerId: '',
          ownerName: '',
          price: rentAmount,
          deposit: 0,
          bedrooms: 0,
          bathrooms: 0,
          squareFeet: 0,
          amenities: [],
          images: [],
          status: PropertyStatus.occupied,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    // Calculate next rent date automatically
    // Rent is typically due monthly on the same day as the lease start date
    DateTime nextRentDate;
    final now = DateTime.now();
    final leaseStart = tenantData!.leaseStartDate ?? tenantData!.createdAt;
    
    // Find the next anniversary of the lease start day
    DateTime potentialDate = DateTime(now.year, now.month, leaseStart.day);
    
    // If the day is already passed this month, move to next month
    if (potentialDate.isBefore(now) || (potentialDate.day == now.day && potentialDate.month == now.month && potentialDate.year == now.year)) {
       // Correctly handle month overflow (e.g. going from Jan 31 to Feb)
       int nextMonth = now.month + 1;
       int nextYear = now.year;
       if (nextMonth > 12) {
         nextMonth = 1;
         nextYear++;
       }
       
       // Handle cases where the day doesn't exist in the next month (e.g. Jan 31 -> Feb 28)
       int day = leaseStart.day;
       int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
       if (day > lastDayOfNextMonth) {
         day = lastDayOfNextMonth;
       }
       
       nextRentDate = DateTime(nextYear, nextMonth, day);
    } else {
       nextRentDate = potentialDate;
    }

    final daysRemaining = nextRentDate.difference(now).inDays + 1; // +1 to be inclusive of the day
    final isDueSoon = daysRemaining <= 5;

    // Format currency
    final amount = rentAmount.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
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
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning, color: Colors.orange, size: 16),
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
                'Due in $daysRemaining Days (${nextRentDate.day}/${nextRentDate.month}/${nextRentDate.year})',
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
                    // Navigate to payment page with required parameters
                    // Note: You may need to pass a proper applicationId if available
                    // For now, using tenantId as a fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          applicationId: tenantData!.id, // or use a specific applicationId if you have one
                          amount: rentAmount,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E95FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                  onPressed: () {
                    // Show payment history or options
                    _showPaymentOptions(context);
                  },
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
                  'Secure payment via M-Pesa',
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

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF4E95FF)),
              title: const Text('Payment History', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'View past transactions',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to payment history page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment history coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF4E95FF)),
              title: const Text('Download Receipt', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Get your payment receipts',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement receipt download
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt download coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: Color(0xFF4E95FF)),
              title: const Text('Auto-Pay Setup', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'Set up automatic payments',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement auto-pay setup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auto-pay setup coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
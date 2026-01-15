import 'package:flutter/material.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/models/property_model.dart'; // Add this import
import '../../../data/models/address_model.dart'; // Add this import

class UpcomingRentCard extends StatelessWidget {
  final TenantModel? tenantData;
  final bool isLoading;
  final List<PropertyModel> properties; // Add this to find the property by unitId

  const UpcomingRentCard({
    super.key,
    required this.tenantData,
    required this.isLoading,
    required this.properties, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (tenantData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No upcoming rent information available.'),
        ),
      );
    }

    // Find the property associated with the tenant's unitId
    final property = properties.firstWhere(
      (p) => p.unitId == tenantData!.unitId,
      orElse: () => PropertyModel(
        id: '',
        title: '',
        unitId: '',
        description: '',
        address: AddressModel(
          street: '',
          city: '',
          state: '',
          zipCode: '',
          // country: '',
          // fullAddress: '',
        ),
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
      ), // Default empty property if not found
    );

    // Calculate next rent date (e.g., assuming monthly rent, next due date)
    final nextRentDate = tenantData!.leaseStartDate?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30));
    final formattedDate = '${nextRentDate.month}/${nextRentDate.day}/${nextRentDate.year}';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Rent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Next payment due: $formattedDate',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: KES ${property.price}', // Use property.price instead of tenantData.price
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            // Add more details if available, e.g., lease end date
            if (tenantData!.leaseEndDate != null)
              Text(
                'Lease ends: ${tenantData!.leaseEndDate!.month}/${tenantData!.leaseEndDate!.day}/${tenantData!.leaseEndDate!.year}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

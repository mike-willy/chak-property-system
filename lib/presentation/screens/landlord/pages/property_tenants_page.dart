import 'package:flutter/material.dart';
import '../../../../data/models/tenant_model.dart';
import '../../widgets/tenant_list_item.dart';

class PropertyTenantsPage extends StatelessWidget {
  final String propertyName;
  final List<TenantModel> tenants;

  const PropertyTenantsPage({
    super.key,
    required this.propertyName,
    required this.tenants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141725),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2235),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              propertyName.isNotEmpty ? propertyName : 'Property Tenants',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              '${tenants.length} Tenant${tenants.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tenants.isEmpty
          ? Center(
              child: Text(
                'No tenants found',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenants.length,
              itemBuilder: (context, index) {
                return TenantListItem(
                  tenant: tenants[index],
                  showPropertyName: false,
                  showPhone: true,
                  onTap: () {
                    // Navigate to tenant details if needed
                  },
                );
              },
            ),
    );
  }
}

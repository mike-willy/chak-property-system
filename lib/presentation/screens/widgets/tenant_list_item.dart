import 'package:flutter/material.dart';
import '../../../../data/models/tenant_model.dart';

class TenantListItem extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback? onTap;

  const TenantListItem({
    super.key,
    required this.tenant,
    this.onTap,
    this.showPropertyName = true,
    this.showPhone = false,
  });

  final bool showPropertyName;
  final bool showPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4E95FF).withOpacity(0.2),
          child: Text(
            tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : 'T',
            style: const TextStyle(color: Color(0xFF4E95FF), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          tenant.fullName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    showPropertyName 
                        ? '${tenant.propertyName} • Unit ${tenant.unitNumber}'
                        : 'Unit ${tenant.unitNumber}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (showPhone && tenant.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 4),
                  Text(
                    tenant.phone,
                    style: TextStyle(color: Colors.blue.shade400, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(tenant.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getStatusColor(tenant.status).withOpacity(0.3)),
          ),
          child: Text(
            tenant.status.value.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(tenant.status),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return Colors.green;
      case TenantStatus.inactive:
        return Colors.orange;
      case TenantStatus.evicted:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

// presentation/screens/properties/widgets/property_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../data/models/property_model.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final Function(PropertyStatus) onStatusChanged;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onView,
    required this.onEdit,
    required this.onStatusChanged,
  });

  String getStatusText(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.occupied:
        return 'Occupied';
      case PropertyStatus.vacant:
        return 'Vacant';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.marketing:
        return 'Marketing';
      case PropertyStatus.paid:
        return 'Paid';
    }
  }

  Color getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.occupied:
      case PropertyStatus.paid:
        return Colors.green;
      case PropertyStatus.vacant:
      case PropertyStatus.marketing:
        return Colors.orange;
      case PropertyStatus.maintenance:
        return Colors.red;
    }
  }

  IconData getStatusIcon(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.occupied:
        return FontAwesomeIcons.userCheck;
      case PropertyStatus.vacant:
        return FontAwesomeIcons.doorClosed;
      case PropertyStatus.maintenance:
        return FontAwesomeIcons.tools;
      case PropertyStatus.marketing:
        return FontAwesomeIcons.bullhorn;
      case PropertyStatus.paid:
        return FontAwesomeIcons.checkCircle;
    }
  }

  String formatCurrency(double amount) {
    return 'KES ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1E2235), // Dark Theme Card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truncateText(property.title, 20),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.locationDot,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                truncateText(property.address.fullAddress, 30),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500, // Grey text
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(property.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getStatusColor(property.status).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(property.status),
                          size: 10,
                          color: getStatusColor(property.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getStatusText(property.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: getStatusColor(property.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Property Details
              Row(
                children: [
                  _buildDetailItem(
                    icon: FontAwesomeIcons.bed,
                    text: '${property.bedrooms} Beds',
                  ),
                  const SizedBox(width: 16),
                  _buildDetailItem(
                    icon: FontAwesomeIcons.bath,
                    text: '${property.bathrooms} Baths',
                  ),
                  const SizedBox(width: 16),
                  _buildDetailItem(
                    icon: FontAwesomeIcons.rulerCombined,
                    text: '${property.squareFeet.toInt()} sq ft',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Rent and Deposit
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141725), // Ultra dark background for price
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Rent',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(property.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 30, 
                      width: 1, 
                      color: Colors.grey.shade800
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Deposit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                         const SizedBox(height: 2),
                        Text(
                          formatCurrency(property.deposit),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Description Preview
              if (property.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truncateText(property.description, 80),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onView,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: Colors.white,
                      ),
                       child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View Details'),
                          SizedBox(width: 8),
                          Icon(FontAwesomeIcons.arrowRight, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
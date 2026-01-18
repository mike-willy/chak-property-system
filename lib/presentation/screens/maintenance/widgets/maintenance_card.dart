// presentation/screens/maintenance/widgets/maintenance_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/maintenance_model.dart';

class MaintenanceCard extends StatelessWidget {
  final MaintenanceModel request;
  final VoidCallback onView;
  final Function(MaintenanceStatus)? onStatusChanged;

  const MaintenanceCard({
    super.key,
    required this.request,
    required this.onView,
    this.onStatusChanged,
  });

  String getStatusText(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return 'Pending';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.onHold:
        return 'On Hold';
      case MaintenanceStatus.canceled:
        return 'Cancelled';
    }
  }

  Color getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return Colors.orange;
      case MaintenanceStatus.inProgress:
        return Colors.blue;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.onHold:
        return Colors.purple;
      case MaintenanceStatus.canceled:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.open:
        return FontAwesomeIcons.circleExclamation;
      case MaintenanceStatus.inProgress:
        return FontAwesomeIcons.hammer;
      case MaintenanceStatus.completed:
        return FontAwesomeIcons.circleCheck;
      case MaintenanceStatus.onHold:
        return FontAwesomeIcons.circlePause;
      case MaintenanceStatus.canceled:
        return FontAwesomeIcons.circleXmark;
    }
  }

  String getPriorityText(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return 'Low';
      case MaintenancePriority.medium:
        return 'Medium';
      case MaintenancePriority.high:
        return 'High';
    }
  }

  Color getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.low:
        return Colors.green;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.high:
        return Colors.red;
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1E2235), // Dark Theme Card Color
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(request.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.building, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${request.propertyName.isNotEmpty ? request.propertyName : 'Unknown'} • ${request.unitName.isNotEmpty ? request.unitName : request.unitId}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(request.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getStatusColor(request.status).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getStatusIcon(request.status),
                          size: 12,
                          color: getStatusColor(request.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getStatusText(request.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: getStatusColor(request.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Priority Badge & Images
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getPriorityColor(request.priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.exclamationTriangle,
                          size: 10,
                          color: getPriorityColor(request.priority),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getPriorityText(request.priority) + ' Priority',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: getPriorityColor(request.priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (request.images.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                       padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.image,
                            size: 10,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${request.images.length} photos',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),

              // Description Preview
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400, // Lighter grey for description
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onView,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.white,
                  ),
                   child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Details'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// presentation/screens/maintenance/pages/maintenance_detail_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/maintenance_model.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/auth_provider.dart';

class MaintenanceDetailPage extends StatefulWidget {
  final MaintenanceModel request;

  const MaintenanceDetailPage({
    super.key,
    required this.request,
  });

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Request'),
        elevation: 0,
      ),
      body: Consumer2<MaintenanceProvider, AuthProvider>(
        builder: (context, maintenanceProvider, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Find live request from provider
                Builder(
                  builder: (context) {
                    final request = maintenanceProvider.requests.firstWhere(
                      (r) => r.id == widget.request.id,
                      orElse: () => widget.request,
                    );
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Priority Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusCard(request.status),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPriorityCard(request.priority),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.fileLines,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  request.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Details Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  icon: FontAwesomeIcons.building,
                                  label: 'Property',
                                  value: request.propertyName.isNotEmpty 
                                      ? request.propertyName 
                                      : 'Unknown Property',
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  icon: FontAwesomeIcons.doorOpen,
                                  label: 'Unit Name',
                                  value: request.unitName.isNotEmpty 
                                      ? request.unitName 
                                      : request.unitId,
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  icon: FontAwesomeIcons.user,
                                  label: 'Tenant',
                                  value: request.tenantName.isNotEmpty 
                                      ? request.tenantName 
                                      : 'Unknown Tenant',
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  icon: FontAwesomeIcons.calendar,
                                  label: 'Created',
                                  value: DateFormat('MMM dd, yyyy • hh:mm a').format(request.createdAt),
                                ),
                                const Divider(),
                                _buildDetailRow(
                                  icon: FontAwesomeIcons.clock,
                                  label: 'Last Updated',
                                  value: DateFormat('MMM dd, yyyy • hh:mm a').format(request.updatedAt),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Images Section
                        if (request.images.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        FontAwesomeIcons.image,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Images (${request.images.length})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: request.images.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              request.images[index],
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.broken_image),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Status Update Section (for landlords)
                        if (authProvider.isLandlord && 
                            request.status != MaintenanceStatus.completed &&
                            request.status != MaintenanceStatus.canceled) ...[
                          const SizedBox(height: 24),
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Update Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (request.status == MaintenanceStatus.open)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(
                                              context,
                                              maintenanceProvider,
                                              MaintenanceStatus.inProgress,
                                            ),
                                            icon: const Icon(FontAwesomeIcons.hammer, size: 14),
                                            label: const Text('Start Work'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      if (request.status == MaintenanceStatus.inProgress) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(
                                              context,
                                              maintenanceProvider,
                                              MaintenanceStatus.completed,
                                            ),
                                            icon: const Icon(FontAwesomeIcons.circleCheck, size: 14),
                                            label: const Text('Complete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(
                                              context,
                                              maintenanceProvider,
                                              MaintenanceStatus.onHold,
                                            ),
                                            icon: const Icon(FontAwesomeIcons.circlePause, size: 14),
                                            label: const Text('Hold'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (request.status == MaintenanceStatus.onHold)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(
                                              context,
                                              maintenanceProvider,
                                              MaintenanceStatus.inProgress,
                                            ),
                                            icon: const Icon(FontAwesomeIcons.hammer, size: 14),
                                            label: const Text('Resume'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      if (request.status != MaintenanceStatus.completed && 
                                          request.status != MaintenanceStatus.canceled) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _updateStatus(
                                              context,
                                              maintenanceProvider,
                                              MaintenanceStatus.canceled,
                                            ),
                                            icon: const Icon(FontAwesomeIcons.circleXmark, size: 14),
                                            label: const Text('Cancel'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(color: Colors.red),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(MaintenanceStatus status) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case MaintenanceStatus.open:
        statusText = 'Pending';
        statusColor = Colors.orange;
        statusIcon = FontAwesomeIcons.circleExclamation;
        break;
      case MaintenanceStatus.inProgress:
        statusText = 'In Progress';
        statusColor = Colors.blue;
        statusIcon = FontAwesomeIcons.hammer;
        break;
      case MaintenanceStatus.completed:
        statusText = 'Completed';
        statusColor = Colors.green;
        statusIcon = FontAwesomeIcons.circleCheck;
        break;
      case MaintenanceStatus.onHold:
        statusText = 'On Hold';
        statusColor = Colors.purple;
        statusIcon = FontAwesomeIcons.circlePause;
        break;
      case MaintenanceStatus.canceled:
        statusText = 'Cancelled';
        statusColor = Colors.grey;
        statusIcon = FontAwesomeIcons.circleXmark;
        break;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityCard(MaintenancePriority priority) {
    String priorityText;
    Color priorityColor;

    switch (priority) {
      case MaintenancePriority.low:
        priorityText = 'Low';
        priorityColor = Colors.green;
        break;
      case MaintenancePriority.medium:
        priorityText = 'Medium';
        priorityColor = Colors.orange;
        break;
      case MaintenancePriority.high:
        priorityText = 'High';
        priorityColor = Colors.red;
        break;
    }

    return Card(
      color: priorityColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.exclamationTriangle,
              color: priorityColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '$priorityText Priority',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: priorityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    MaintenanceProvider provider,
    MaintenanceStatus newStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          newStatus == MaintenanceStatus.completed
              ? 'Mark as Completed?'
              : newStatus == MaintenanceStatus.onHold
                  ? 'Put on Hold?'
                  : newStatus == MaintenanceStatus.canceled
                      ? 'Cancel Request?'
                      : 'Update Status?',
        ),
        content: Text(
          newStatus == MaintenanceStatus.completed
              ? 'Are you sure you want to mark this request as completed?'
              : newStatus == MaintenanceStatus.onHold
                  ? 'Are you sure you want to put this request on hold?'
                  : newStatus == MaintenanceStatus.canceled
                      ? 'Are you sure you want to cancel this maintenance request?'
                      : 'Are you sure you want to update the status of this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.updateRequestStatus(widget.request.id, newStatus);
      if (!mounted) return;

      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == MaintenanceStatus.completed
                  ? 'Request marked as completed'
                  : 'Status updated successfully',
            ),
          ),
        );
        setState(() {}); // Refresh UI
      }
    }
  }
}


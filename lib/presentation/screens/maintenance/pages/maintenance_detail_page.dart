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
                // Status and Priority Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(widget.request.status),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriorityCard(widget.request.priority),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  widget.request.title,
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
                          widget.request.description,
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
                          icon: FontAwesomeIcons.home,
                          label: 'Unit ID',
                          value: widget.request.unitId,
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: FontAwesomeIcons.calendar,
                          label: 'Created',
                          value: DateFormat('MMM dd, yyyy • hh:mm a').format(widget.request.createdAt),
                        ),
                        const Divider(),
                        _buildDetailRow(
                          icon: FontAwesomeIcons.clock,
                          label: 'Last Updated',
                          value: DateFormat('MMM dd, yyyy • hh:mm a').format(widget.request.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                // Images Section
                if (widget.request.images.isNotEmpty) ...[
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
                                'Images (${widget.request.images.length})',
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
                              itemCount: widget.request.images.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.request.images[index],
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
                if (authProvider.isLandlord && widget.request.status != MaintenanceStatus.completed) ...[
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
                              if (widget.request.status == MaintenanceStatus.open)
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
                              if (widget.request.status == MaintenanceStatus.inProgress) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(
                                      context,
                                      maintenanceProvider,
                                      MaintenanceStatus.completed,
                                    ),
                                    icon: const Icon(FontAwesomeIcons.circleCheck, size: 14),
                                    label: const Text('Mark Complete'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
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
        statusText = 'Open';
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
              : 'Start Work?',
        ),
        content: Text(
          newStatus == MaintenanceStatus.completed
              ? 'Are you sure you want to mark this request as completed?'
              : 'Are you sure you want to start working on this request?',
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


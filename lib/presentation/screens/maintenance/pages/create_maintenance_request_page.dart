// presentation/screens/maintenance/pages/create_maintenance_request_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/maintenance_model.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/property_provider.dart';

class CreateMaintenanceRequestPage extends StatefulWidget {
  final String? unitId;
  final String? propertyId;

  const CreateMaintenanceRequestPage({
    super.key,
    this.unitId,
    this.propertyId,
  });

  @override
  State<CreateMaintenanceRequestPage> createState() => _CreateMaintenanceRequestPageState();
}

class _CreateMaintenanceRequestPageState extends State<CreateMaintenanceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  MaintenancePriority _selectedPriority = MaintenancePriority.medium;
  String? _selectedUnitId;
  List<String> _images = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.unitId;
    // Load properties/units if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = context.read<PropertyProvider>();
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.loadProperties();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUnitId == null || _selectedUnitId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<MaintenanceProvider>();
    await provider.createRequest(
      unitId: _selectedUnitId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      images: _images,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance request submitted successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Maintenance Request'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Unit Selection
            Consumer<PropertyProvider>(
              builder: (context, propertyProvider, _) {
                if (propertyProvider.isTenant) {
                  // For tenants, show a simple text field for unit ID
                  return TextFormField(
                    initialValue: _selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Unit ID / Unit Number',
                      hintText: 'Enter your unit ID or number',
                      prefixIcon: Icon(FontAwesomeIcons.home),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit ID';
                      }
                      return null;
                    },
                  );
                } else {
                  // For landlords, show dropdown of their properties/units
                  return DropdownButtonFormField<String>(
                    value: _selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Select Unit',
                      prefixIcon: Icon(FontAwesomeIcons.home),
                      border: OutlineInputBorder(),
                    ),
                    items: propertyProvider.properties
                        .expand((property) {
                          // For now, use property ID as unit ID
                          // In production, you'd fetch actual units
                          return [property.id];
                        })
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Text('Unit: $id'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a unit';
                      }
                      return null;
                    },
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief description of the issue',
                prefixIcon: Icon(FontAwesomeIcons.heading),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of the maintenance issue',
                prefixIcon: Icon(FontAwesomeIcons.fileLines),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Priority Selection
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPriorityChip(
                    priority: MaintenancePriority.low,
                    label: 'Low',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPriorityChip(
                    priority: MaintenancePriority.medium,
                    label: 'Medium',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPriorityChip(
                    priority: MaintenancePriority.high,
                    label: 'High',
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRequest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(FontAwesomeIcons.paperPlane),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip({
    required MaintenancePriority priority,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedPriority == priority;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.exclamationTriangle,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


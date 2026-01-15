// presentation/screens/maintenance/pages/create_maintenance_request_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/maintenance_model.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/property_provider.dart';
import '../../../../providers/auth_provider.dart'; // Add this import
import '../../../../data/repositories/tenant_repository.dart'; // Add this import

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
  final _descriptionController = TextEditingController();
  MaintenancePriority _selectedPriority = MaintenancePriority.medium;
  String? _selectedUnitId;
  String? _selectedTitle; // Changed from controller to string for dropdown
  List<String> _images = [];
  bool _isSubmitting = false;
  bool _isLoadingUnit = false; // For loading tenant unit

  // Predefined title options
  final List<String> _titleOptions = ['Water', 'Drainage', 'Electricity', 'Walks', 'Roof'];

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.unitId;
    _selectedTitle = _titleOptions.first; // Default to first option

    // Load properties/units if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider = context.read<PropertyProvider>();
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.loadProperties();
      }

      // For tenants, fetch their associated unit
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isTenant) {
        _loadTenantUnit(authProvider.firebaseUser?.uid);
      }
    });
  }

  Future<void> _loadTenantUnit(String? userId) async {
    if (userId == null) return;

    setState(() {
      _isLoadingUnit = true;
    });

    try {
      final tenantRepo = TenantRepository(); // Instantiate TenantRepository
      final tenant = await tenantRepo.getTenantByUserId(userId);
      if (tenant != null && tenant.unitId.isNotEmpty) {
        setState(() {
          _selectedUnitId = tenant.unitId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load your allocated unit. Please contact support.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading unit: $e')),
      );
    } finally {
      setState(() {
        _isLoadingUnit = false;
      });
    }
  }

  @override
  void dispose() {
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

    if (_selectedTitle == null || _selectedTitle!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a title')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<MaintenanceProvider>();
    await provider.createRequest(
      unitId: _selectedUnitId!,
      title: _selectedTitle!, // Use selected title
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
    final authProvider = context.watch<AuthProvider>();

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
            if (_isLoadingUnit)
              const Center(child: CircularProgressIndicator())
            else
              Consumer<PropertyProvider>(
                builder: (context, propertyProvider, _) {
                  if (authProvider.isTenant) {
                    // For tenants, show the auto-selected unit (read-only)
                    return TextFormField(
                      initialValue: _selectedUnitId ?? 'Unit not found',
                      decoration: const InputDecoration(
                        labelText: 'Your Unit ID',
                        prefixIcon: Icon(FontAwesomeIcons.home),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Make it read-only
                      validator: (value) {
                        if (value == null || value.isEmpty || value == 'Unit not found') {
                          return 'Unit not available. Please contact support.';
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

            // Title Dropdown
            DropdownButtonFormField<String>(
              value: _selectedTitle,
              decoration: const InputDecoration(
                labelText: 'Issue Category',
                hintText: 'Select the type of issue',
                prefixIcon: Icon(FontAwesomeIcons.list),
                border: OutlineInputBorder(),
              ),
              items: _titleOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTitle = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an issue category';
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


// presentation/screens/maintenance/pages/create_maintenance_request_page.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/maintenance_model.dart';
import '../../../../providers/maintenance_provider.dart';
import '../../../../providers/property_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/repositories/tenant_repository.dart';
import '../../../../data/repositories/property_repository.dart';
import '../../../../data/datasources/remote_datasource.dart';
import '../../../../data/models/tenant_model.dart';
import '../../../../data/models/unit_model.dart';
import '../../../../data/models/property_model.dart';
import '../../../../data/models/address_model.dart';

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
  String? _selectedPropertyId;
  String? _selectedUnitId;
  String? _selectedUnitName;
  String? _selectedPropertyName;
  String? _selectedTitle; // Changed from controller to string for dropdown
  List<String> _images = [];
  bool _isSubmitting = false;
  bool _isLoadingUnit = false; // For loading tenant unit
  bool _isLoadingUnits = false; // For loading property units
  List<Map<String, dynamic>> _propertyUnits = [];
  TenantModel? _currentTenant; // Store the tenant model

  // Predefined title options
  // final List<String> _titleOptions = ['Water', 'Drainage', 'Electricity', 'Walks', 'Roof'];

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.unitId;
    _selectedPropertyId = widget.propertyId;
    _selectedTitle = null; // Default to null for dynamic list

    // Load properties/units if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final maintenanceProvider = context.read<MaintenanceProvider>();
      maintenanceProvider.loadCategories(); // Load categories

      final propertyProvider = context.read<PropertyProvider>();
      if (propertyProvider.properties.isEmpty) {
        propertyProvider.loadProperties();
      }

      // For tenants, fetch their associated unit
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isTenant) {
        _loadTenantUnit(authProvider.firebaseUser?.uid);
      } else if (_selectedPropertyId != null) {
        // For landlords, if propertyId is provided, load its units
        _loadPropertyUnits(_selectedPropertyId!);
      }
    });
  }

  Future<void> _loadPropertyUnits(String propertyId) async {
    setState(() {
      _isLoadingUnits = true;
      _propertyUnits = [];
    });

    try {
      final propertyRepo = PropertyRepository(RemoteDataSource(FirebaseFirestore.instance));
      final result = await propertyRepo.getPropertyUnits(propertyId);
      
      result.fold(
        (failure) => debugPrint('Error loading units: ${failure.message}'),
        (units) {
          setState(() {
            _propertyUnits = units;
            // If unitId was pre-selected, resolve its name
            if (_selectedUnitId != null) {
              final unitMap = units.firstWhere(
                (u) => u['id'] == _selectedUnitId,
                orElse: () => {},
              );
              if (unitMap.isNotEmpty) {
                _selectedUnitName = unitMap['unitNumber'];
              }
            }
          });
        },
      );
    } catch (e) {
      debugPrint('Exception loading units: $e');
    } finally {
      setState(() {
        _isLoadingUnits = false;
      });
    }
  }

  Future<void> _loadTenantUnit(String? userId) async {
    if (userId == null) return;

    setState(() {
      _isLoadingUnit = true;
    });

    try {
      final tenantRepo = TenantRepository(); // Instantiate TenantRepository
      final tenant = await tenantRepo.getTenantByUserId(userId);
      
      if (tenant != null) {
        setState(() {
          _currentTenant = tenant;
          if (tenant.unitId.isNotEmpty) {
            _selectedUnitId = tenant.unitId;
          }
          if (tenant.propertyId.isNotEmpty) {
            _selectedPropertyId = tenant.propertyId;
          }
          
          // Resolve building and unit names if they are IDs or empty
          _resolveHumanReadableNames(tenant);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load your profile. Please contact support.')),
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

  Future<void> _resolveHumanReadableNames(TenantModel tenant) async {
    String pName = tenant.propertyName;
    String uName = tenant.unitNumber;

    final propertyRepo = PropertyRepository(RemoteDataSource(FirebaseFirestore.instance));

    // If property name is an ID or empty
    if (pName.isEmpty || pName == tenant.propertyId) {
      final pResult = await propertyRepo.getPropertyById(tenant.propertyId);
      pResult.fold(
        (_) {},
        (prop) => pName = prop.title,
      );
    }

    // If unit name is an ID or empty
    if (uName.isEmpty || uName == tenant.unitId) {
      final uResult = await propertyRepo.getPropertyUnit(tenant.propertyId, tenant.unitId);
      uResult.fold(
        (_) {},
        (unit) => uName = unit.unitNumber,
      );
    }

    if (mounted) {
      setState(() {
        _selectedPropertyName = pName;
        _selectedUnitName = uName;
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
    final propertyProvider = context.read<PropertyProvider>();
    
    // Resolve names for submission
    String finalPropertyName = _selectedPropertyName ?? 'Unknown';
    String finalUnitName = _selectedUnitName ?? 'Unknown';
    String finalTenantName = _currentTenant?.fullName ?? 'Unknown';

    // Last ditch resolution if still unknown (mostly for landlords who just selected from dropdown)
    if (finalPropertyName == 'Unknown' && _selectedPropertyId != null) {
      final prop = propertyProvider.properties.firstWhere(
        (p) => p.id == _selectedPropertyId,
        orElse: () => PropertyModel(
          id: '', 
          title: 'Unknown', 
          description: '', 
          unitId: '', 
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
          updatedAt: DateTime.now()
        ),
      );
      if (prop.id.isNotEmpty) finalPropertyName = prop.title;
    }

    if (finalUnitName == 'Unknown' && _selectedUnitId != null && _propertyUnits.isNotEmpty) {
      final unitMap = _propertyUnits.firstWhere(
        (u) => u['id'] == _selectedUnitId,
        orElse: () => {},
      );
      if (unitMap.isNotEmpty) finalUnitName = unitMap['unitNumber'] ?? _selectedUnitId!;
    }

    await provider.createRequest(
      unitId: _selectedUnitId!,
      title: _selectedTitle!,
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
      tenantName: finalTenantName,
      propertyName: finalPropertyName,
      unitName: finalUnitName,
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
                    return Column(
                      children: [
                        TextFormField(
                          key: ValueKey('prop_${_selectedPropertyName}'),
                          initialValue: _selectedPropertyName ?? 'Loading building...',
                          decoration: const InputDecoration(
                            labelText: 'Building',
                            prefixIcon: Icon(FontAwesomeIcons.building),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: ValueKey('unit_${_selectedUnitName}'),
                          initialValue: _selectedUnitName ?? 'Loading unit...',
                          decoration: const InputDecoration(
                            labelText: 'Unit / Door Number',
                            prefixIcon: Icon(FontAwesomeIcons.doorOpen),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (_selectedUnitId == null || _selectedUnitId!.isEmpty) {
                              return 'Unit information not found.';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
                  } else {
                    // For landlords, show dropdown of their properties and then units
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedPropertyId,
                          decoration: const InputDecoration(
                            labelText: 'Select Property',
                            prefixIcon: Icon(FontAwesomeIcons.building),
                            border: OutlineInputBorder(),
                          ),
                          items: propertyProvider.properties
                              .map((property) => DropdownMenuItem(
                                    value: property.id,
                                    child: Text(property.title),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPropertyId = value;
                              _selectedUnitId = null;
                              _selectedUnitName = null;
                              _selectedPropertyName = propertyProvider.properties
                                  .firstWhere((p) => p.id == value).title;
                              if (value != null) {
                                _loadPropertyUnits(value);
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a property';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingUnits)
                          const LinearProgressIndicator()
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedUnitId,
                            decoration: const InputDecoration(
                              labelText: 'Select Unit',
                              prefixIcon: Icon(FontAwesomeIcons.doorOpen),
                              border: OutlineInputBorder(),
                            ),
                            items: _propertyUnits
                                .map((unit) => DropdownMenuItem(
                                      value: unit['id'] as String,
                                      child: Text('Unit: ${unit['unitNumber'] ?? unit['id']}'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUnitId = value;
                                final unitMap = _propertyUnits.firstWhere((u) => u['id'] == value);
                                _selectedUnitName = unitMap['unitNumber'];
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a unit';
                              }
                              return null;
                            },
                          ),
                      ],
                    );
                  }
                },
              ),

            const SizedBox(height: 24),

            // Title Dropdown
            Consumer<MaintenanceProvider>(
              builder: (context, maintenanceProvider, child) {
                 final categories = maintenanceProvider.categories;
                 
                 return DropdownButtonFormField<String>(
                  value: _selectedTitle,
                  decoration: const InputDecoration(
                    labelText: 'Issue Category',
                    hintText: 'Select the type of issue',
                    prefixIcon: Icon(FontAwesomeIcons.list),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.isEmpty 
                    ? [] 
                    : categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.name),
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
                );
              }
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


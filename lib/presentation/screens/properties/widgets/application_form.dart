import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../data/models/application_model.dart';
import 'application_section.dart';
import '../pages/application_status_page.dart';

class ApplicationForm extends StatefulWidget {
  final String propertyId;
  final String? unitId;

  const ApplicationForm({
    super.key,
    required this.propertyId,
    this.unitId,
  });

  @override
  State<ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<ApplicationForm> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  
  // Emergency Contact
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  
  final _messageCtrl = TextEditingController();

  // Dates
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;
  
  // Fees from Firestore
  double _monthlyRent = 0;
  double _securityDeposit = 0;
  double _applicationFee = 0;
  double _petDeposit = 0;
  String _otherFees = '';
  int _leaseTerm = 12;
  int _noticePeriod = 30;
  double _latePaymentFee = 0;
  int _gracePeriod = 5;
  Map<String, dynamic>? _feeDetails;
  
  // Pet Information
  bool _hasPet = false;
  final _petTypeCtrl = TextEditingController();
  final _petBreedCtrl = TextEditingController();
  final _petWeightCtrl = TextEditingController();
  final _petAgeCtrl = TextEditingController();
  
  // Unit Selection
  String? _selectedUnitId;
  Map<String, dynamic>? _selectedUnitData;
  List<Map<String, dynamic>> _availableUnits = [];
  
  // Property statistics
  int _totalUnits = 0;
  int _vacantCount = 0;
  int _leasedCount = 0;
  int _maintenanceCount = 0;
  double _occupancyRate = 0;
  
  bool _loading = false;
  bool _loadingData = true;
  bool _loadingUnits = true;
  Map<String, dynamic>? _propertyData;

  @override
  void initState() {
    super.initState();
    _loadPropertyData();
    final auth = context.read<AuthProvider>();

    _nameCtrl.text = auth.userProfile?.name ?? '';
    _emailCtrl.text = auth.userProfile?.email ?? '';
    _phoneCtrl.text = auth.userProfile?.phone ?? '';
  }

  Future<void> _loadPropertyData() async {
    try {
      await _checkExistingApplication();
      if (!mounted) return;

      // Load property data
      final propertyDoc = await FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.propertyId)
          .get();
          
      if (propertyDoc.exists) {
        _propertyData = {
          'id': propertyDoc.id,
          ...propertyDoc.data()!
        };
        
        print('Loaded property: ${_propertyData!['name']}');
        
        // Load fee information from property
        _monthlyRent = (_propertyData!['rentAmount'] ?? 0).toDouble();
        _securityDeposit = (_propertyData!['securityDeposit'] ?? _monthlyRent).toDouble();
        _applicationFee = (_propertyData!['applicationFee'] ?? 0).toDouble();
        _petDeposit = (_propertyData!['petDeposit'] ?? 0).toDouble();
        _otherFees = _propertyData!['otherFees'] ?? '';
        _leaseTerm = _propertyData!['leaseTerm'] ?? 12;
        _noticePeriod = _propertyData!['noticePeriod'] ?? 30;
        _latePaymentFee = (_propertyData!['latePaymentFee'] ?? 0).toDouble();
        _gracePeriod = _propertyData!['gracePeriod'] ?? 5;
        _feeDetails = _propertyData!['feeDetails'] ?? {
          'includesWater': false,
          'includesElectricity': false,
          'includesInternet': false,
          'includesMaintenance': false
        };

        // Load unit statistics from property.unitDetails
        final unitDetails = _propertyData!['unitDetails'] ?? {};
        _totalUnits = unitDetails['totalUnits'] ?? _propertyData!['units'] ?? 1;
        _vacantCount = unitDetails['vacantCount'] ?? _totalUnits;
        _leasedCount = unitDetails['leasedCount'] ?? 0;
        _maintenanceCount = unitDetails['maintenanceCount'] ?? 0;
        
        // Calculate occupancy rate
        if (_totalUnits > 0) {
          _occupancyRate = (_leasedCount / _totalUnits) * 100;
        }

        // Load available units for this property
        await _loadAvailableUnits();
      }

      setState(() {
        _loadingData = false;
      });
    } catch (e) {
      print('Error loading property data: $e');
      setState(() {
        _loadingData = false;
      });
    }
  }

  Future<void> _loadAvailableUnits() async {
    try {
      setState(() {
        _loadingUnits = true;
      });

      print('=== STARTING UNIT FETCH ===');
      print('Property ID: ${widget.propertyId}');
      print('Vacant count from property: $_vacantCount');
      
      List<Map<String, dynamic>> unitsList = [];

      // APPROACH 1: Try subcollection with various status field values
      print('\nAttempt 1: Querying subcollection properties/{id}/units');
      try {
        final unitsRef = FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.propertyId)
            .collection('units');
        
        // Try to get ALL units first to see what's available
        final allUnitsQuery = await unitsRef.get();
        print('Total units in subcollection: ${allUnitsQuery.docs.length}');
        
        // Print all units for debugging
        for (var doc in allUnitsQuery.docs) {
          final data = doc.data();
          print('Unit ${doc.id}: ${data['unitNumber']} - Status: ${data['status']} - isAvailable: ${data['isAvailable']}');
        }
        
        // Try different status queries
        List<String> statusValues = ['vacant', 'available', 'Vacant', 'Available'];
        for (var status in statusValues) {
          try {
            final vacantQuery = await unitsRef.where('status', isEqualTo: status).get();
            if (vacantQuery.docs.isNotEmpty) {
              print('Found ${vacantQuery.docs.length} units with status: $status');
              unitsList = vacantQuery.docs.map((doc) {
                final data = doc.data();
                return _createUnitMap(doc.id, data);
              }).toList();
              break;
            }
          } catch (e) {
            print('Error querying status "$status": $e');
          }
        }
        
        // If still no units, try isAvailable field
        if (unitsList.isEmpty) {
          try {
            final availableQuery = await unitsRef.where('isAvailable', isEqualTo: true).get();
            if (availableQuery.docs.isNotEmpty) {
              print('Found ${availableQuery.docs.length} units with isAvailable: true');
              unitsList = availableQuery.docs.map((doc) {
                final data = doc.data();
                return _createUnitMap(doc.id, data);
              }).toList();
            }
          } catch (e) {
            print('Error querying isAvailable: $e');
          }
        }
        
        // If still no units, just take all units
        if (unitsList.isEmpty && allUnitsQuery.docs.isNotEmpty) {
          print('Taking all ${allUnitsQuery.docs.length} units from subcollection');
          unitsList = allUnitsQuery.docs.map((doc) {
            final data = doc.data();
            return _createUnitMap(doc.id, data);
          }).toList();
        }
        
      } catch (e) {
        print('Error with subcollection approach: $e');
      }

      // APPROACH 2: Try separate units collection
      if (unitsList.isEmpty) {
        print('\nAttempt 2: Querying separate units collection');
        try {
          final unitsQuery = await FirebaseFirestore.instance
              .collection('units')
              .where('propertyId', isEqualTo: widget.propertyId)
              .get();

          print('Found ${unitsQuery.docs.length} units in separate collection');
          
          // Try different status filters
          List<QueryDocumentSnapshot> vacantUnits = [];
          for (var doc in unitsQuery.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase();
            final isAvailable = data['isAvailable'] ?? false;
            
            if (status == 'vacant' || status == 'available' || isAvailable == true) {
              vacantUnits.add(doc);
            }
          }
          
          if (vacantUnits.isNotEmpty) {
            print('Found ${vacantUnits.length} vacant/available units');
            unitsList = vacantUnits.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _createUnitMap(doc.id, data);
            }).toList();
          } else if (unitsQuery.docs.isNotEmpty) {
            print('No vacant units found, taking all ${unitsQuery.docs.length} units');
            unitsList = unitsQuery.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _createUnitMap(doc.id, data);
            }).toList();
          }
        } catch (e) {
          print('Error with separate collection approach: $e');
        }
      }

      // APPROACH 3: Check if units are stored in property.unitDetails.units array
      if (unitsList.isEmpty) {
        print('\nAttempt 3: Checking property.unitDetails.units array');
        try {
          final unitDetails = _propertyData?['unitDetails'] ?? {};
          final unitsArray = unitDetails['units'];
          
          if (unitsArray != null && unitsArray is List && unitsArray.isNotEmpty) {
            print('Found ${unitsArray.length} units in unitDetails.units array');
            unitsList = unitsArray.where((unit) {
              final status = (unit['status'] ?? 'vacant').toString().toLowerCase();
              final isAvailable = unit['isAvailable'] ?? false;
              return status == 'vacant' || status == 'available' || isAvailable == true;
            }).map((unit) {
              return _createUnitMap(
                unit['id'] ?? unit['unitNumber']?.toString() ?? 'array_${DateTime.now().millisecondsSinceEpoch}',
                unit
              );
            }).toList();
          }
        } catch (e) {
          print('Error with array approach: $e');
        }
      }

      // APPROACH 4: Create mock units based on vacant count
      if (unitsList.isEmpty && _vacantCount > 0) {
        print('\nCreating $_vacantCount mock units based on vacant count');
        unitsList = List.generate(_vacantCount, (index) {
          final unitNum = index + 1;
          return {
            'id': 'mock_unit_${widget.propertyId}_$unitNum',
            'unitNumber': unitNum.toString(),
            'unitName': 'Unit $unitNum',
            'type': _propertyData?['propertyType'] ?? 'Apartment',
            'bedrooms': _propertyData?['bedrooms'] ?? 1,
            'bathrooms': _propertyData?['bathrooms'] ?? 1,
            'size': _propertyData?['size'],
            'monthlyRent': _monthlyRent,
            'securityDeposit': _securityDeposit,
            'applicationFee': _applicationFee,
            'status': 'vacant',
            'description': 'Unit $unitNum - ${_propertyData?['name'] ?? 'Property'}',
            'features': [],
            'amenities': [],
            'isAvailable': true,
          };
        });
      }

      _availableUnits = unitsList;
      print('\n=== UNIT FETCH COMPLETE ===');
      print('Total available units found: ${_availableUnits.length}');
      for (var unit in _availableUnits.take(5)) {
        print('  Unit ${unit['unitNumber']}: ${unit['unitName']} - Rent: ${unit['monthlyRent']}');
      }
      if (_availableUnits.length > 5) {
        print('  ... and ${_availableUnits.length - 5} more units');
      }

      // Sort units by unitNumber or unitOrder
      _availableUnits.sort((a, b) {
        final numA = int.tryParse(a['unitNumber']?.toString() ?? '0') ?? a['unitOrder'] ?? 0;
        final numB = int.tryParse(b['unitNumber']?.toString() ?? '0') ?? b['unitOrder'] ?? 0;
        return numA.compareTo(numB);
      });

      // If a specific unit was provided and it's in the available units, select it
      if (widget.unitId != null) {
        final unit = _availableUnits.firstWhere(
          (unit) => unit['id'] == widget.unitId || unit['unitNumber'] == widget.unitId,
          orElse: () => {},
        );
        if (unit.isNotEmpty) {
          _selectedUnitId = unit['id'];
          _selectedUnitData = unit;
          _updateRentForSelectedUnit();
          print('Pre-selected unit: ${unit['unitNumber']}');
        }
      }

      // If no unit pre-selected and there are available units, select the first one
      if (_selectedUnitId == null && _availableUnits.isNotEmpty) {
        _selectedUnitId = _availableUnits[0]['id'];
        _selectedUnitData = _availableUnits[0];
        _updateRentForSelectedUnit();
        print('Auto-selected first unit: ${_selectedUnitData?['unitNumber']}');
      }

      setState(() {
        _loadingUnits = false;
      });
    } catch (e) {
      print('Error loading units: $e');
      setState(() {
        _loadingUnits = false;
      });
    }
  }

  Map<String, dynamic> _createUnitMap(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'unitNumber': data['unitNumber']?.toString() ?? data['unitOrder']?.toString() ?? 'N/A',
      'unitName': data['unitName'] ?? 'Unit ${data['unitNumber']}',
      'type': data['type'] ?? _propertyData?['propertyType'] ?? 'Apartment',
      'bedrooms': data['bedrooms'] ?? _propertyData?['bedrooms'] ?? 1,
      'bathrooms': data['bathrooms'] ?? _propertyData?['bathrooms'] ?? 1,
      'size': data['size'] ?? _propertyData?['size'],
      'monthlyRent': data['rentAmount'] ?? data['monthlyRent'] ?? _monthlyRent,
      'securityDeposit': data['securityDeposit'] ?? _securityDeposit,
      'applicationFee': data['applicationFee'] ?? _applicationFee,
      'status': data['status'] ?? 'vacant',
      'isAvailable': data['isAvailable'] ?? true,
      'description': data['description'] ?? '',
      'features': data['features'] ?? [],
      'amenities': data['amenities'] ?? [],
      'unitOrder': data['unitOrder'] ?? 0,
      'rentAmount': data['rentAmount'],
      'unitId': data['unitId'],
    };
  }

  Future<void> _checkExistingApplication() async {
    final auth = context.read<AuthProvider>();
    if (auth.firebaseUser == null) return;

    // Check for pending applications for this property by this user
    // We fetch all pending applications for this user and filter in memory 
    // to avoid needing a specific composite index immediately
    final query = await FirebaseFirestore.instance
        .collection('tenantApplications')
        .where('tenantId', isEqualTo: auth.firebaseUser!.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (query.docs.isNotEmpty) {
      // Check if any of these are for the current property
      final existingApp = query.docs.firstWhere(
        (doc) => doc['propertyId'] == widget.propertyId,
        orElse: () => query.docs.first, // Fallback (shouldn't be hit if we filter right, but logic below handles it)
      );
      
      // Specifically check if the found doc is for this property
      if (existingApp['propertyId'] == widget.propertyId) {
         if (!mounted) return;
         
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('You already have a pending application for this property.'),
             backgroundColor: Colors.blue,
           ),
         );

         Navigator.pushReplacement(
           context,
           MaterialPageRoute(
             builder: (context) => ApplicationStatusPage(
               applicationId: existingApp.id,
             ),
           ),
         );
      }
    }
  }

  void _updateRentForSelectedUnit() {
    if (_selectedUnitData != null) {
      // Use unit-specific rent if available, otherwise use property rent
      final unitMonthlyRent = _selectedUnitData!['monthlyRent'] ?? _selectedUnitData!['rentAmount'] ?? _monthlyRent;
      final unitSecurityDeposit = _selectedUnitData!['securityDeposit'] ?? _securityDeposit;
      final unitApplicationFee = _selectedUnitData!['applicationFee'] ?? _applicationFee;
      
      setState(() {
        _monthlyRent = unitMonthlyRent.toDouble();
        _securityDeposit = unitSecurityDeposit.toDouble();
        _applicationFee = unitApplicationFee.toDouble();
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Allow selection up to 2 years in future
    );
    
    if (picked != null) {
      setState(() {
        _leaseStartDate = picked;
        // Calculate end date based on lease term
        _leaseEndDate = DateTime(
          picked.year,
          picked.month + _leaseTerm,
          picked.day,
        );
      });
    }
  }

  double get _totalEstimatedFees {
    double total = _monthlyRent + _securityDeposit + _applicationFee;
    if (_hasPet && _petDeposit > 0) {
      total += _petDeposit;
    }
    return total;
  }

  bool get _isMultiUnitProperty => _totalUnits > 1;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit')),
      );
      return;
    }

    if (_leaseStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select lease start date')),
      );
      return;
    }

    // Validate pet information if has pet
    if (_hasPet) {
      if (_petTypeCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify your pet type')),
        );
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);

    try {
      final doc =
          FirebaseFirestore.instance.collection('tenantApplications').doc();

      final application = ApplicationModel.newApplication(
        id: doc.id,
        tenantId: auth.firebaseUser!.uid,
        unitId: _selectedUnitId!,
      );

      // Prepare pet information
      final petInfo = _hasPet ? {
        'hasPet': true,
        'petType': _petTypeCtrl.text.trim(),
        'petBreed': _petBreedCtrl.text.trim(),
        'petWeight': _petWeightCtrl.text.trim(),
        'petAge': _petAgeCtrl.text.trim(),
        'petDepositRequired': _petDeposit > 0,
        'petDepositAmount': _petDeposit,
      } : {
        'hasPet': false,
        'petDepositRequired': false,
        'petDepositAmount': 0,
      };

      await doc.set({
        ...application.toMap(),
        'propertyId': widget.propertyId,
        'unitId': _selectedUnitId!,
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'idNumber': _idNumberCtrl.text.trim(),
        'monthlyRent': _monthlyRent,
        'securityDeposit': _securityDeposit,
        'applicationFee': _applicationFee,
        'petDeposit': _hasPet ? _petDeposit : 0,
        'otherFees': _otherFees,
        'leaseTerm': _leaseTerm,
        'noticePeriod': _noticePeriod,
        'latePaymentFee': _latePaymentFee,
        'gracePeriod': _gracePeriod,
        'feeDetails': _feeDetails,
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'leaseStart': Timestamp.fromDate(_leaseStartDate!),
        'leaseEnd': Timestamp.fromDate(_leaseEndDate!),
        'unitNumber': _selectedUnitData?['unitNumber'] ?? '',
        'unitName': _selectedUnitData?['unitName'] ?? 'Unit ${_selectedUnitData?['unitNumber']}',
        'unitType': _selectedUnitData?['type'] ?? 'Apartment',
        'bedrooms': _selectedUnitData?['bedrooms'] ?? _propertyData?['bedrooms'] ?? 1,
        'bathrooms': _selectedUnitData?['bathrooms'] ?? _propertyData?['bathrooms'] ?? 1,
        'unitSize': _selectedUnitData?['size'] ?? _propertyData?['size'],
        'propertyName': _propertyData?['name'] ?? '',
        'propertyAddress': _propertyData?['address'] ?? '',
        'propertyCity': _propertyData?['city'] ?? '',
        'propertyType': _propertyData?['propertyType'] ?? _propertyData?['type'] ?? 'Apartment',
        'landlordName': _propertyData?['landlordName'] ?? 'Unknown',
        'status': 'pending',
        'submittedAt': Timestamp.now(),
        'totalFees': _totalEstimatedFees,
        'hasPet': _hasPet,
        'petInfo': petInfo,
        'petDetails': _hasPet ? {
          'type': _petTypeCtrl.text.trim(),
          'breed': _petBreedCtrl.text.trim(),
          'weight': _petWeightCtrl.text.trim(),
          'age': _petAgeCtrl.text.trim(),
        } : null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to status page replacing the current route so they can't go back to form easily
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ApplicationStatusPage(
            applicationId: doc.id,
          ),
        ),
      );
    } catch (e) {
      print('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Info Card with Statistics
            if (_propertyData != null)
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applying for:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_propertyData!['name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_propertyData!['address']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Property Statistics Row
                      Row(
                        children: [
                          _infoChip(_propertyData!['propertyType'] ?? _propertyData!['type'] ?? 'Apartment'),
                          const SizedBox(width: 8),
                          if (_propertyData!['bedrooms'] != null)
                            _infoChip('${_propertyData!['bedrooms']} Bed'),
                          const SizedBox(width: 8),
                          if (_propertyData!['bathrooms'] != null)
                            _infoChip('${_propertyData!['bathrooms']} Bath'),
                          if (_propertyData!['size'] != null) ...[
                            const SizedBox(width: 8),
                            _infoChip('${_propertyData!['size']} sq ft'),
                          ],
                        ],
                      ),
                      
                      // Property Statistics for Multi-unit properties
                      if (_isMultiUnitProperty) ...[
                        const SizedBox(height: 16),
                        _buildPropertyStatistics(),
                      ],
                      
                      // Debug button (temporary - remove in production)
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            print('=== DEBUG INFO ===');
                            print('Property ID: ${widget.propertyId}');
                            print('Property Name: ${_propertyData?['name']}');
                            print('Total Units: $_totalUnits');
                            print('Vacant Count: $_vacantCount');
                            print('Leased Count: $_leasedCount');
                            print('Maintenance Count: $_maintenanceCount');
                            print('Loading Units: $_loadingUnits');
                            print('Available Units: ${_availableUnits.length}');
                            
                            // Try to directly query the subcollection
                            try {
                              print('\n=== DIRECT FIRESTORE QUERY ===');
                              final unitsRef = FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(widget.propertyId)
                                  .collection('units');
                              
                              final allUnits = await unitsRef.get();
                              print('Direct query - Total docs in subcollection: ${allUnits.docs.length}');
                              
                              for (var doc in allUnits.docs) {
                                final data = doc.data();
                                print('  Doc ID: ${doc.id}');
                                print('  Data: $data');
                                print('  ---');
                              }
                            } catch (e) {
                              print('Direct query error: $e');
                            }
                            
                            print('Selected Unit: $_selectedUnitId');
                            print('Selected Unit Data: $_selectedUnitData');
                            print('==================');
                          },
                          child: const Text('Debug Info'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Section 1: Unit Selection
            ApplicationSection(title: 'Select Unit'),
            const SizedBox(height: 16),
            _buildUnitSelectionSection(),

            // Show selected unit details if any unit is selected
            if (_selectedUnitId != null && _selectedUnitData != null) ...[
              const SizedBox(height: 16),
              _buildSelectedUnitDetails(),
            ],

            // Section 2: Personal Information
            ApplicationSection(title: 'Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoSection(),

            // Section 3: Lease Period
            ApplicationSection(title: 'Lease Period'),
            const SizedBox(height: 16),
            _buildLeasePeriodSection(),

            // Section 4: Pet Information
            ApplicationSection(title: 'Pet Information'),
            const SizedBox(height: 16),
            _buildPetInformationSection(),

            // Section 5: Financial Information
            ApplicationSection(title: 'Financial Information'),
            const SizedBox(height: 16),
            _buildFinancialSection(),

            // Section 6: Emergency Contact
            ApplicationSection(title: 'Emergency Contact'),
            const SizedBox(height: 16),
            _buildEmergencyContactSection(),

            // Section 7: Additional Information
            ApplicationSection(title: 'Additional Information'),
            const SizedBox(height: 16),
            _buildAdditionalInfoSection(),

            // Section 8: Terms and Conditions
            ApplicationSection(title: 'Terms and Conditions'),
            const SizedBox(height: 16),
            _buildTermsSection(),

            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Statistics:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        
        // Unit Status Statistics
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              icon: Icons.home,
              label: 'Total Units',
              value: '$_totalUnits',
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.door_front_door,
              label: 'Vacant',
              value: '$_vacantCount',
              color: Colors.green,
            ),
            _buildStatItem(
              icon: Icons.check_circle,
              label: 'Leased',
              value: '$_leasedCount',
              color: Colors.orange,
            ),
            if (_maintenanceCount > 0)
              _buildStatItem(
                icon: Icons.build,
                label: 'Maintenance',
                value: '$_maintenanceCount',
                color: Colors.red,
              ),
          ],
        ),
        
        // Occupancy Rate
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Occupancy Rate:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: MediaQuery.of(context).size.width * 0.7 * (_occupancyRate / 100),
                        decoration: BoxDecoration(
                          color: _occupancyRate >= 80 ? Colors.green : 
                                 _occupancyRate >= 50 ? Colors.orange : Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_occupancyRate.toStringAsFixed(1)}% Occupied',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (_vacantCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.door_front_door, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '$_vacantCount Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue.shade50,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildUnitSelectionSection() {
    if (_loadingUnits) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_availableUnits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
          color: Colors.red.shade50,
        ),
        child: Column(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No Available Units',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no vacant units available in this property.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check back later or contact the property manager.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await _loadAvailableUnits();
                  setState(() {});
                },
                child: const Text('Retry Unit Fetch'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a unit from the available options:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Found ${_availableUnits.length} vacant unit${_availableUnits.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: _selectedUnitId,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
            hint: const Text('Select a unit'),
            onChanged: (String? newValue) {
              if (newValue != null) {
                final selectedUnit = _availableUnits.firstWhere(
                  (unit) => unit['id'] == newValue,
                );
                setState(() {
                  _selectedUnitId = newValue;
                  _selectedUnitData = selectedUnit;
                  _updateRentForSelectedUnit();
                });
              }
            },
            items: _availableUnits.map<DropdownMenuItem<String>>((unit) {
              final unitNumber = unit['unitNumber'] ?? 'N/A';
              final unitName = unit['unitName'] ?? 'Unit $unitNumber';
              final unitType = unit['type'] ?? 'Apartment';
              final bedrooms = unit['bedrooms'] ?? _propertyData?['bedrooms'] ?? 1;
              final bathrooms = unit['bathrooms'] ?? _propertyData?['bathrooms'] ?? 1;
              final unitRent = unit['monthlyRent'] ?? _monthlyRent;
              final unitSize = unit['size'] ?? _propertyData?['size'];
              
              return DropdownMenuItem<String>(
                value: unit['id'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$unitName - KSh ${NumberFormat('#,##0').format(unitRent)}/month',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Unit $unitNumber',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$bedrooms Bed, $bathrooms Bath',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (unitSize != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$unitSize sq ft',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedUnitDetails() {
    if (_selectedUnitData == null) return const SizedBox();

    final unitNumber = _selectedUnitData!['unitNumber'] ?? 'N/A';
    final unitName = _selectedUnitData!['unitName'] ?? 'Unit $unitNumber';
    final unitType = _selectedUnitData!['type'] ?? 'Apartment';
    final bedrooms = _selectedUnitData!['bedrooms'] ?? _propertyData?['bedrooms'] ?? 1;
    final bathrooms = _selectedUnitData!['bathrooms'] ?? _propertyData?['bathrooms'] ?? 1;
    final unitSize = _selectedUnitData!['size'] ?? _propertyData?['size'];
    final description = _selectedUnitData!['description'] ?? '';
    final features = _selectedUnitData!['features'] ?? [];
    final amenities = _selectedUnitData!['amenities'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Unit: $unitName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rent: KSh ${NumberFormat('#,##0').format(_monthlyRent)}/month',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 28,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Unit Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unit Details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _unitDetailChip('Unit $unitNumber'),
                  _unitDetailChip(unitType),
                  _unitDetailChip('$bedrooms Bed'),
                  _unitDetailChip('$bathrooms Bath'),
                  if (unitSize != null) _unitDetailChip('$unitSize sq ft'),
                ],
              ),
            ],
          ),
          
          // Unit Description (if available)
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Unit Features (if available)
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Features:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map<Widget>((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    feature.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Unit Amenities (if available)
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Amenities:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map<Widget>((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 12, color: Colors.purple.shade600),
                      const SizedBox(width: 4),
                      Text(
                        amenity.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _unitDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameCtrl,
          label: 'Full Name *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailCtrl,
          label: 'Email Address *',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneCtrl,
          label: 'Phone Number *',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _idNumberCtrl,
          label: 'ID/Passport Number *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your ID/Passport number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLeasePeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lease Term: $_leaseTerm months',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Notice Period: $_noticePeriod days',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Lease Start Date (Move-in Date) *',
          date: _leaseStartDate,
          onTap: () => _selectStartDate(context),
        ),
        const SizedBox(height: 16),
        // Show calculated end date
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lease End Date (Calculated):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _leaseEndDate != null
                          ? DateFormat('MMMM dd, yyyy').format(_leaseEndDate!)
                          : 'Select start date first',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _leaseEndDate != null ? Colors.blue : Colors.grey,
                      ),
                    ),
                    if (_leaseEndDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Automatically calculated based on $_leaseTerm months from start date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetInformationSection() {
    List<Widget> petWidgets = [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pets,
                  color: _hasPet ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Do you have a pet?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_petDeposit > 0)
                      Text(
                        'Pet deposit: KSh ${NumberFormat('#,##0').format(_petDeposit)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _hasPet ? Colors.green : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Switch(
              value: _hasPet,
              onChanged: (value) {
                setState(() {
                  _hasPet = value;
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    ];

    if (_hasPet) {
      petWidgets.addAll([
        const SizedBox(height: 16),
        Text(
          'Pet Details *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _petTypeCtrl,
          label: 'Pet Type (e.g., Dog, Cat, Bird) *',
          hintText: 'Enter pet type',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _petBreedCtrl,
          label: 'Breed (Optional)',
          hintText: 'Enter breed if known',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _petWeightCtrl,
                label: 'Weight (Optional)',
                hintText: 'e.g., 10 kg',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _petAgeCtrl,
                label: 'Age (Optional)',
                hintText: 'e.g., 2 years',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Note: Additional pet deposit of KSh ${NumberFormat('#,##0').format(_petDeposit)} will be added to your fees',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]);
    } else if (_petDeposit > 0) {
      petWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Property allows pets with a deposit of KSh ${NumberFormat('#,##0').format(_petDeposit)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
            ),
          ),
        ),
      );
    } else {
      petWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Property does not require a pet deposit',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: petWidgets,
    );
  }

  Widget _buildFinancialSection() {
    List<Widget> financialWidgets = [
      if (_selectedUnitId != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(4),
            color: Colors.blue.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.home, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_selectedUnitData?['unitName'] ?? 'Unit ${_selectedUnitData?['unitNumber']}'} - KSh ${NumberFormat('#,##0').format(_monthlyRent)}/month',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      
      _buildFeeCard(
        icon: Icons.attach_money,
        label: 'Monthly Rent',
        amount: _monthlyRent,
      ),
      
      _buildFeeCard(
        icon: Icons.security,
        label: 'Security Deposit',
        amount: _securityDeposit,
        note: 'Typically equal to one month\'s rent',
      ),
    ];

    if (_applicationFee > 0) {
      financialWidgets.add(
        _buildFeeCard(
          icon: Icons.description,
          label: 'Application Fee',
          amount: _applicationFee,
          color: Colors.red.shade50,
          textColor: Colors.red,
        ),
      );
    }
    
    if (_petDeposit > 0 && _hasPet) {
      financialWidgets.add(
        _buildFeeCard(
          icon: Icons.pets,
          label: 'Pet Deposit',
          amount: _petDeposit,
          color: Colors.green.shade50,
          textColor: Colors.green,
        ),
      );
    }
    
    if (_latePaymentFee > 0) {
      financialWidgets.add(
        _buildFeeCard(
          icon: Icons.warning,
          label: 'Late Payment Fee',
          amount: _latePaymentFee,
          details: 'KSh ${NumberFormat('#,##0').format(_latePaymentFee)} per day (After $_gracePeriod days grace)',
          color: Colors.red.shade50,
          textColor: Colors.red,
          showAmount: false,
        ),
      );
    }
    
    if (_otherFees.isNotEmpty) {
      financialWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              const Icon(Icons.money, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Other Fees: $_otherFees',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    List<Widget> totalFeeContent = [
      Text(
        'Total Estimated Fees: KSh ${NumberFormat('#,##0').format(_totalEstimatedFees)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ];

    if (_hasPet && _petDeposit > 0) {
      totalFeeContent.add(
        Text(
          'Includes pet deposit of KSh ${NumberFormat('#,##0').format(_petDeposit)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.green.shade700,
          ),
        ),
      );
    }

    financialWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green),
          borderRadius: BorderRadius.circular(4),
          color: Colors.green.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calculate, size: 20, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: totalFeeContent,
              ),
            ),
          ],
        ),
      ),
    );
    
    if (_feeDetails != null) {
      List<Widget> includedChips = [];
      
      if (_feeDetails!['includesWater'] == true) {
        includedChips.add(_feeChip('💧 Water', Colors.blue));
      }
      if (_feeDetails!['includesElectricity'] == true) {
        includedChips.add(_feeChip('⚡ Electricity', Colors.amber));
      }
      if (_feeDetails!['includesInternet'] == true) {
        includedChips.add(_feeChip('🌐 Internet', Colors.purple));
      }
      if (_feeDetails!['includesMaintenance'] == true) {
        includedChips.add(_feeChip('🔧 Maintenance', Colors.green));
      }
      if (_feeDetails!['includesWater'] != true &&
          _feeDetails!['includesElectricity'] != true &&
          _feeDetails!['includesInternet'] != true &&
          _feeDetails!['includesMaintenance'] != true) {
        includedChips.add(_feeChip('No utilities included', Colors.grey));
      }

      financialWidgets.addAll([
        const SizedBox(height: 16),
        Text(
          'What\'s Included:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: includedChips,
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: financialWidgets,
    );
  }

  Widget _buildFeeCard({
    required IconData icon,
    required String label,
    required double amount,
    String? note,
    String? details,
    Color? color,
    Color? textColor,
    bool showAmount = true,
  }) {
    List<Widget> cardChildren = [
      Row(
        children: [
          Icon(icon, size: 20, color: textColor ?? Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? Colors.black,
                  ),
                ),
                if (details != null)
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor?.withOpacity(0.8) ?? Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          if (showAmount)
            Text(
              'KSh ${NumberFormat('#,##0').format(amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.black,
              ),
            ),
        ],
      ),
    ];

    if (note != null) {
      cardChildren.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 32),
          child: Text(
            note,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
        color: color ?? Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cardChildren,
      ),
    );
  }

  Widget _feeChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _emergencyNameCtrl,
          label: 'Emergency Contact Name *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter emergency contact name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emergencyPhoneCtrl,
          label: 'Emergency Contact Phone *',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter emergency contact phone';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      children: [
        TextFormField(
          controller: _messageCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tell us about yourself',
            hintText: 'Why should we choose you? Tell us about your rental history, employment, etc.',
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please tell us about yourself';
            }
            if (value.length < 50) {
              return 'Please provide more details (at least 50 characters)';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us understand you better and process your application faster',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    List<Widget> terms = [
      Text(
        'By submitting this application, you agree to:',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 8),
    ];

    String termsText = '1. Pay the application fee of KSh ${NumberFormat('#,##0').format(_applicationFee)} (non-refundable)\n'
          '2. Pay the security deposit of KSh ${NumberFormat('#,##0').format(_securityDeposit)} upon approval\n';

    if (_hasPet && _petDeposit > 0) {
      termsText += '3. Pay the pet deposit of KSh ${NumberFormat('#,##0').format(_petDeposit)} if approved with pet\n';
    } else if (_petDeposit > 0) {
      termsText += '3. Pet deposit of KSh ${NumberFormat('#,##0').format(_petDeposit)} applies if you get a pet later\n';
    }

    termsText += '4. Provide a $_noticePeriod day notice before moving out\n'
          '5. Comply with all property rules and regulations\n'
          '6. Allow credit and background checks\n'
          '7. Provide proof of income and references';

    terms.add(Text(
      termsText,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
      ),
    ));

    if (_hasPet) {
      terms.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Note: Pet approval is subject to property rules and may require additional documentation.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: terms,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMMM dd, yyyy').format(date)
                    : 'Select $label',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    List<Widget> submitWidgets = [
      Text(
        'Application Fee: KSh ${NumberFormat('#,##0').format(_applicationFee)}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    ];

    if (_hasPet && _petDeposit > 0) {
      submitWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '+ Pet Deposit: KSh ${NumberFormat('#,##0').format(_petDeposit)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ),
      );
    }

    submitWidgets.addAll([
      const SizedBox(height: 8),
      Text(
        'Application fee is non-refundable and covers processing costs',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (_selectedUnitId == null || _loading) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Submit Application & Pay Fee',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    ]);

    return Column(
      children: submitWidgets,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _idNumberCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _messageCtrl.dispose();
    _petTypeCtrl.dispose();
    _petBreedCtrl.dispose();
    _petWeightCtrl.dispose();
    _petAgeCtrl.dispose();
    super.dispose();
  }
}
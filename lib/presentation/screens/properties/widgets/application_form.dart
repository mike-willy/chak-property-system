import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../data/models/application_model.dart';
import 'application_section.dart';

class ApplicationForm extends StatefulWidget {
  final String propertyId;
  final String unitId;

  const ApplicationForm({
    super.key,
    required this.propertyId,
    required this.unitId,
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
  
  // Financial Information
  final _monthlyRentCtrl = TextEditingController();
  final _securityDepositCtrl = TextEditingController();
  
  // Emergency Contact
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  
  final _messageCtrl = TextEditingController();

  // Dates
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;
  
  bool _loading = false;
  bool _loadingData = true;
  Map<String, dynamic>? _unitData;
  Map<String, dynamic>? _propertyData;

  @override
  void initState() {
    super.initState();
    _loadPropertyAndUnitData();
    final auth = context.read<AuthProvider>();

    _nameCtrl.text = auth.userProfile?.name ?? '';
    _emailCtrl.text = auth.userProfile?.email ?? '';
    _phoneCtrl.text = auth.userProfile?.phone ?? '';
  }

  Future<void> _loadPropertyAndUnitData() async {
    try {
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
      }

      // Load unit data
      final unitDoc = await FirebaseFirestore.instance
          .collection('units')
          .doc(widget.unitId)
          .get();
          
      if (unitDoc.exists) {
        _unitData = {
          'id': unitDoc.id,
          ...unitDoc.data()!
        };
        
        // Pre-fill monthly rent
        final monthlyRent = _unitData!['monthlyRent'] ?? 0;
        _monthlyRentCtrl.text = monthlyRent.toString();
        _securityDepositCtrl.text = monthlyRent.toString();
      }

      setState(() {
        _loadingData = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _loadingData = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _leaseStartDate = picked;
          if (_leaseEndDate != null && _leaseEndDate!.isBefore(picked)) {
            _leaseEndDate = null;
          }
        } else {
          _leaseEndDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_leaseStartDate == null || _leaseEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select lease start and end dates')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);

    try {
      final doc =
          FirebaseFirestore.instance.collection('tenantApplications').doc();

      final application = ApplicationModel.newApplication(
        id: doc.id,
        tenantId: auth.firebaseUser!.uid,
        unitId: widget.unitId,
      );

      final monthlyRent = double.tryParse(_monthlyRentCtrl.text) ?? 0;
      final securityDeposit = double.tryParse(_securityDepositCtrl.text) ?? monthlyRent;

      await doc.set({
        ...application.toMap(),
        'propertyId': widget.propertyId,
        'unitId': widget.unitId,
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'idNumber': _idNumberCtrl.text.trim(),
        'monthlyRent': monthlyRent,
        'securityDeposit': securityDeposit,
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'leaseStart': Timestamp.fromDate(_leaseStartDate!),
        'leaseEnd': Timestamp.fromDate(_leaseEndDate!),
        'unitNumber': _unitData?['unitNumber'] ?? '',
        'propertyName': _propertyData?['name'] ?? '',
        'propertyAddress': _propertyData?['address'] ?? '',
        'unitType': _unitData?['type'] ?? 'Apartment',
        'status': 'pending',
        'submittedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
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
            // Property & Unit Info Card
            if (_propertyData != null && _unitData != null)
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
                          color: Colors.grey[600],
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
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoChip('Unit ${_unitData!['unitNumber']}'),
                          const SizedBox(width: 8),
                          _infoChip(_unitData!['type'] ?? 'Apartment'),
                          const SizedBox(width: 8),
                          _infoChip(
                            'KSh ${NumberFormat('#,##0').format(_unitData!['monthlyRent'] ?? 0)}/month',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Section 1: Personal Information
            ApplicationSection(title: 'Personal Information'),
            const SizedBox(height: 16),
            _buildPersonalInfoSection(),

            // Section 2: Lease Period
            ApplicationSection(title: 'Lease Period'),
            const SizedBox(height: 16),
            _buildLeasePeriodSection(),

            // Section 3: Financial Information
            ApplicationSection(title: 'Financial Information'),
            const SizedBox(height: 16),
            _buildFinancialSection(),

            // Section 4: Emergency Contact
            ApplicationSection(title: 'Emergency Contact'),
            const SizedBox(height: 16),
            _buildEmergencyContactSection(),

            // Section 5: Additional Information
            ApplicationSection(title: 'Additional Information'),
            const SizedBox(height: 16),
            _buildAdditionalInfoSection(),

            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.blue[50],
      visualDensity: VisualDensity.compact,
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
          label: 'ID/Passport Number',
          hintText: 'Optional',
        ),
      ],
    );
  }

  Widget _buildLeasePeriodSection() {
    return Column(
      children: [
        _buildDateField(
          label: 'Lease Start Date *',
          date: _leaseStartDate,
          onTap: () => _selectDate(context, true),
        ),
        const SizedBox(height: 16),
        _buildDateField(
          label: 'Lease End Date *',
          date: _leaseEndDate,
          onTap: () => _selectDate(context, false),
        ),
      ],
    );
  }

  Widget _buildFinancialSection() {
    return Column(
      children: [
        _buildTextField(
          controller: _monthlyRentCtrl,
          label: 'Expected Monthly Rent (KSh) *',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter monthly rent';
            }
            final rent = double.tryParse(value);
            if (rent == null || rent <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _securityDepositCtrl,
          label: 'Security Deposit (KSh) *',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter security deposit';
            }
            final deposit = double.tryParse(value);
            if (deposit == null || deposit <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Typically equal to one month\'s rent',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
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
            color: Colors.grey[600],
          ),
        ),
      ],
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
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
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
                'Submit Application',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _idNumberCtrl.dispose();
    _monthlyRentCtrl.dispose();
    _securityDepositCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }
}
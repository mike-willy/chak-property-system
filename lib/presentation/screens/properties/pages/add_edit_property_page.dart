import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/data/models/property_model.dart';
import 'package:mobile_app/data/models/address_model.dart';
import 'package:mobile_app/providers/property_provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/core/common/validators.dart';
import 'package:mobile_app/presentation/themes/theme_colors.dart';

class AddEditPropertyPage extends StatefulWidget {
  final PropertyModel? property; // If null, we are in Add mode

  const AddEditPropertyPage({super.key, this.property});

  @override
  State<AddEditPropertyPage> createState() => _AddEditPropertyPageState();
}

class _AddEditPropertyPageState extends State<AddEditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _priceController;
  late final TextEditingController _depositController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _sizeController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _streetController = TextEditingController(text: p?.address.street ?? '');
    _cityController = TextEditingController(text: p?.address.city ?? '');
    _stateController = TextEditingController(text: p?.address.state ?? '');
    _zipController = TextEditingController(text: p?.address.zipCode ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _depositController = TextEditingController(text: p?.deposit.toString() ?? '');
    _bedroomsController = TextEditingController(text: p?.bedrooms.toString() ?? '');
    _bathroomsController = TextEditingController(text: p?.bathrooms.toString() ?? '');
    _sizeController = TextEditingController(text: p?.squareFeet.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final propertyProvider = context.read<PropertyProvider>();
      
      final ownerId = authProvider.userId;
      final ownerName = authProvider.userProfile?.name ?? 'Unknown';

      if (ownerId == null) throw Exception('User not logged in');

      final address = AddressModel(
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
      );

      final newProperty = PropertyModel(
        id: widget.property?.id ?? '', // ID handled by repo for new items
        title: _titleController.text.trim(),
        unitId: widget.property?.unitId ?? '',
        description: _descriptionController.text.trim(),
        address: address,
        ownerId: ownerId,
        ownerName: ownerName,
        price: double.tryParse(_priceController.text) ?? 0,
        deposit: double.tryParse(_depositController.text) ?? 0,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        squareFeet: double.tryParse(_sizeController.text) ?? 0,
        amenities: widget.property?.amenities ?? [],
        images: widget.property?.images ?? [],
        status: widget.property?.status ?? PropertyStatus.vacant,
        createdAt: widget.property?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.property == null) {
        // Create
        await propertyProvider.createProperty(newProperty); 
      } else {
        // Update
        await propertyProvider.updateProperty(newProperty);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property saved successfully')),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving property: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.property == null ? 'Add Property' : 'Edit Property'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildSectionTitle('Basic Information'),
               TextFormField(
                 controller: _titleController,
                 decoration: const InputDecoration(labelText: 'Property Title'),
                 validator: (v) => Validators.validateRequired(v, 'Title'),
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _descriptionController,
                 decoration: const InputDecoration(labelText: 'Description'),
                 maxLines: 3,
               ),
               const SizedBox(height: 24),
               
               _buildSectionTitle('Location'),
               TextFormField(
                 controller: _streetController,
                 decoration: const InputDecoration(labelText: 'Street Address'),
                 validator: (v) => Validators.validateRequired(v, 'Street'),
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _cityController,
                       decoration: const InputDecoration(labelText: 'City'),
                       validator: (v) => Validators.validateRequired(v, 'City'),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: TextFormField(
                       controller: _stateController,
                       decoration: const InputDecoration(labelText: 'State'),
                       validator: (v) => Validators.validateRequired(v, 'State'),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _zipController,
                 decoration: const InputDecoration(labelText: 'Zip / Postal Code'),
                 keyboardType: TextInputType.number,
               ),
               
               const SizedBox(height: 24),
               _buildSectionTitle('Details'),
               Row(
                 children: [
                   Expanded(child: TextFormField(
                     controller: _priceController,
                     decoration: const InputDecoration(labelText: 'Monthly Rent'),
                     keyboardType: TextInputType.number,
                     validator: (v) => Validators.validateRequired(v, 'Rent'),
                   )),
                   const SizedBox(width: 16),
                   Expanded(child: TextFormField(
                     controller: _depositController,
                     decoration: const InputDecoration(labelText: 'Security Deposit'),
                     keyboardType: TextInputType.number,
                   )),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                   Expanded(child: TextFormField(
                     controller: _bedroomsController,
                     decoration: const InputDecoration(labelText: 'Bedrooms'),
                     keyboardType: TextInputType.number,
                   )),
                   const SizedBox(width: 16),
                   Expanded(child: TextFormField(
                     controller: _bathroomsController,
                     decoration: const InputDecoration(labelText: 'Bathrooms'),
                     keyboardType: TextInputType.number,
                   )),
                   const SizedBox(width: 16),
                   Expanded(child: TextFormField(
                     controller: _sizeController,
                     decoration: const InputDecoration(labelText: 'Sq Ft'),
                     keyboardType: TextInputType.number,
                   )),
                 ],
               ),

               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _saveProperty,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     foregroundColor: Colors.white,
                   ),
                   child: _isLoading 
                       ? const CircularProgressIndicator(color: Colors.white)
                       : const Text('Save Property'),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Colors.white
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_app/data/models/property_model.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/presentation/screens/auth/pages/login_page.dart';
import 'application_page.dart';
import 'package:mobile_app/presentation/screens/properties/widgets/unit_list_widget.dart';
import '../../../../providers/property_provider.dart';
import '../../../../data/models/unit_model.dart';

class PropertyDetailPage extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailPage({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Load units for this property
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadPropertyUnits(widget.property.id);
    });
  }

  String formatCurrency(double amount) {
    // ... (keep existing implementation)
    return 'KES ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  void _handleApply(UnitModel? unit) {
    final auth = context.read<AuthProvider>();

    if (!auth.loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            redirect: '/apply',
            propertyId: widget.property.id,
          ),
        ),
      );
      return;
    }

    if (!auth.isTenant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only tenants can apply for houses')),
      );
      return;
    }

    // Pass specific unitId if selected, otherwise property's default unitId
    final targetUnitId = unit?.id ?? widget.property.unitId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationPage(
          propertyId: widget.property.id,
          unitId: targetUnitId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLandlord = authProvider.isLandlord;

    return Consumer<PropertyProvider>(
      builder: (context, provider, child) {
        final hasUnits = provider.propertyUnits.isNotEmpty;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // 1. App Bar with Image Carousel
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.property.images.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: widget.property.images.length,
                              onPageChanged: (index) {
                                setState(() => _currentImageIndex = index);
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  widget.property.images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, size: 50),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.blue.shade100,
                              child: Icon(
                                FontAwesomeIcons.home,
                                size: 80,
                                color: Colors.blue.shade300,
                              ),
                            ),
                      // Image Indicators
                      if (widget.property.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: widget.property.images.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(
                                    _currentImageIndex == entry.key ? 0.9 : 0.4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.property.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.mapMarkerAlt,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.property.address.fullAddress,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade600,
                                        ),
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
                              color: _getStatusColor(widget.property.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(widget.property.status),
                              ),
                            ),
                            child: Text(
                              widget.property.status.value.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.property.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Landlord Stats Section
                      if (isLandlord) ...[
                        _buildStatsCard(provider.propertyUnitStats),
                        const SizedBox(height: 24),
                      ],

                      // Fees Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Row 1: Rent & Deposit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Rent',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatCurrency(widget.property.price),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.blue.shade200,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Security Deposit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatCurrency(widget.property.deposit),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Divider if optional fees exist
                            if (widget.property.petFee > 0 || widget.property.applicationFee > 0) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(color: Colors.blue.shade200),
                              ),
                              // Row 2: Optional Fees
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (widget.property.applicationFee > 0)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Application Fee',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(widget.property.applicationFee),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                  if (widget.property.petFee > 0)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Pet Fee',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(widget.property.petFee),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key Features Grid
                      const Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureCard(
                            icon: FontAwesomeIcons.bed,
                            label: 'Bedrooms',
                            value: '${widget.property.bedrooms}',
                          ),
                          _buildFeatureCard(
                            icon: FontAwesomeIcons.bath,
                            label: 'Bathrooms',
                            value: '${widget.property.bathrooms}',
                          ),
                          _buildFeatureCard(
                            icon: FontAwesomeIcons.rulerCombined,
                            label: 'Size',
                            value: '${widget.property.squareFeet.toInt()} sq ft',
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      
                      // Unit List (New Section)
                      if (provider.isLoading && provider.propertyUnits.isEmpty)
                         const Center(child: CircularProgressIndicator()),
                      
                      if (hasUnits)
                        UnitListWidget(
                          units: provider.propertyUnits,
                          onApply: _handleApply,
                          isLandlord: isLandlord,
                        ),

                      const SizedBox(height: 10),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.property.description.isNotEmpty
                            ? widget.property.description
                            : 'No description provided.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amenities
                      if (widget.property.amenities.isNotEmpty) ...[
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: widget.property.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    size: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatAmenityName(amenity),
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Landlord Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (widget.property.ownerName.isNotEmpty 
                                    ? widget.property.ownerName[0] 
                                    : 'L').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Managed by',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    widget.property.ownerName.isNotEmpty
                                        ? widget.property.ownerName
                                        : 'Property Manager',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // TODO: Implement contact functionality
                              },
                              icon: const Icon(FontAwesomeIcons.phone),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                // TODO: Implement message functionality
                              },
                              icon: const Icon(FontAwesomeIcons.comment),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Only show bottom button if NO units act as selectors AND not landlord
          bottomNavigationBar: (hasUnits || isLandlord)
              ? null 
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () => _handleApply(null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
// ... (keep the rest of the file same)

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade600),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.occupied:
        return Colors.green;
      case PropertyStatus.vacant:
        return Colors.orange;
      case PropertyStatus.maintenance:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return FontAwesomeIcons.wifi;
      case 'parking':
        return FontAwesomeIcons.car;
      case 'pool':
        return FontAwesomeIcons.swimmingPool;
      case 'gym':
        return FontAwesomeIcons.dumbbell;
      case 'security':
        return FontAwesomeIcons.shieldAlt;
      case 'laundry':
        return FontAwesomeIcons.tshirt;
      case 'tv':
        return FontAwesomeIcons.tv;
      case 'ac':
        return FontAwesomeIcons.snowflake;
      default:
        return FontAwesomeIcons.checkCircle;
    }
  }
  
  String _formatAmenityName(String name) {
    if (name == 'ac') return 'A/C';
    if (name == 'tv') return 'TV';
    return name[0].toUpperCase() + name.substring(1);
  }

  Widget _buildStatsCard(Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Property Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total Units', stats['total'] ?? 0, Colors.blue),
              _buildStatItem('Vacant', stats['vacant'] ?? 0, Colors.green),
              _buildStatItem('Occupied', stats['occupied'] ?? 0, Colors.orange), // Orange typically means "action needed" but here just distinct color
              _buildStatItem('Maint.', stats['maintenance'] ?? 0, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
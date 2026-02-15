import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/unit_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/models/property_model.dart'; // For PropertyModel if needed, or pass property details
import '../pages/application_page.dart';
import '../../auth/pages/login_page.dart';

class UnitDetailPage extends StatefulWidget {
  final UnitModel unit;
  final String propertyId; // Need this for application
  final String propertyName; // Nice to have for context

  const UnitDetailPage({
    super.key,
    required this.unit,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends State<UnitDetailPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  void _handleApply() {
    final auth = context.read<AuthProvider>();

    if (!auth.loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            redirect: '/apply',
            propertyId: widget.propertyId,
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationPage(
          propertyId: widget.propertyId,
          unitId: widget.unit.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = widget.unit.status == UnitStatus.vacant;
    final List<String> displayImages = widget.unit.images.isNotEmpty 
        ? widget.unit.images 
        : []; // Empty list if no images, handle in UI

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
                   if (displayImages.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: displayImages.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          displayImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.blue.shade50,
                      child: Icon(
                        FontAwesomeIcons.doorOpen,
                        size: 80,
                        color: Colors.blue.shade200,
                      ),
                    ),
                  
                  // Image Indicators
                  if (displayImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: displayImages.asMap().entries.map((entry) {
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
                    
                  // Back Button Gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
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
                  // Title and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit ${widget.unit.unitNumber}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.propertyName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(widget.unit.status),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Key Features Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeatureItem(
                        FontAwesomeIcons.layerGroup,
                        'Floor',
                        '${widget.unit.floor}',
                      ),
                      // Add more features if available in UnitModel (e.g., bedrooms/bathrooms if stored there)
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Amenities
                  if (widget.unit.features.isNotEmpty) ...[
                    const Text(
                      'Features & Amenities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.unit.features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isAvailable
          ? Container(
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
                  onPressed: _handleApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply for this Unit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusBadge(UnitStatus status) {
    Color color;
    String label;

    switch (status) {
      case UnitStatus.vacant:
        color = Colors.green;
        label = 'Available';
        break;
      case UnitStatus.occupied:
        color = Colors.red;
        label = 'Occupied';
        break;
      case UnitStatus.maintenance:
        color = Colors.orange;
        label = 'Maintenance';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// presentation/screens/properties/pages/property_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_app/data/models/property_model.dart';
import 'package:mobile_app/presentation/screens/properties/pages/property_detail_page.dart';
import 'package:provider/provider.dart';
import '../../../../providers/property_provider.dart';
import '../widgets/property_card.dart';

class PropertyListPage extends StatefulWidget {
  const PropertyListPage({super.key});

  @override
  State<PropertyListPage> createState() => _PropertyListPageState();
}

class _PropertyListPageState extends State<PropertyListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
    });
  }

  void _loadProperties() {
    final provider = context.read<PropertyProvider>();
    // Only load if properties are empty or if we need to refresh
    if (provider.properties.isEmpty || provider.error != null) {
      provider.loadProperties();
      provider.loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Header Section
              _buildHeaderSection(provider),
              
              // Search and Filter Section
              _buildSearchFilterSection(provider),
              
              // Properties List
              Expanded(
                child: _buildPropertiesList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(PropertyProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isLandlord ? 'My Properties' : 'Available Properties',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.isLandlord 
                        ? 'Manage all your properties' 
                        : 'Browse available homes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              if (provider.isLandlord)
                IconButton(
                  icon: const Icon(FontAwesomeIcons.plusCircle, size: 28),
                  color: Colors.white,
                  onPressed: () {
                    // Navigate to add property
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Top 12',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(provider),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PropertyProvider provider) {
    if (provider.isTenant) return const SizedBox.shrink(); // Hide stats for tenants

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          title: 'Total',
          value: provider.stats['total']?.toString() ?? '0',
          color: Colors.white,
        ),
        _buildStatItem(
          title: 'Occupied',
          value: provider.stats['occupied']?.toString() ?? '0',
          color: Colors.green.shade300,
        ),
        _buildStatItem(
          title: 'Vacant',
          value: provider.stats['vacant']?.toString() ?? '0',
          color: Colors.orange.shade300,
        ),
        _buildStatItem(
          title: 'Maint.',
          value: provider.stats['maintenance']?.toString() ?? '0',
          color: Colors.red.shade300,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterSection(PropertyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: TextEditingController(text: provider.searchTerm),
              decoration: InputDecoration(
                hintText: 'Search properties...',
                prefixIcon: const Icon(
                  FontAwesomeIcons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                suffixIcon: provider.searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          FontAwesomeIcons.times,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          provider.setSearchTerm('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              onChanged: provider.setSearchTerm,
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All',
                  value: 'all',
                  provider: provider,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Occupied',
                  value: 'occupied',
                  icon: FontAwesomeIcons.userCheck,
                  provider: provider,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Vacant',
                  value: 'vacant',
                  icon: FontAwesomeIcons.doorClosed,
                  provider: provider,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Maintenance',
                  value: 'maintenance',
                  icon: FontAwesomeIcons.tools,
                  provider: provider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    IconData? icon,
    required PropertyProvider provider,
  }) {
    final isSelected = provider.filterStatus == value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => provider.setFilterStatus(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesList(PropertyProvider provider) {
    // Debug output
    debugPrint('PropertyListPage: filteredProperties.length = ${provider.filteredProperties.length}');
    debugPrint('PropertyListPage: properties.length = ${provider.properties.length}');
    debugPrint('PropertyListPage: isLoading = ${provider.isLoading}');
    debugPrint('PropertyListPage: error = ${provider.error}');
    
    // Show error if there's an error and no properties
    if (provider.error != null && provider.properties.isEmpty && !provider.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.exclamationTriangle,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  provider.loadProperties();
                  provider.loadStats();
                },
                icon: const Icon(FontAwesomeIcons.rotate),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isLoading && provider.properties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading properties...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Wrap everything in RefreshIndicator so pull-to-refresh works even when list is empty
    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('PropertyListPage: Pull to refresh triggered');
        await provider.loadProperties();
        await provider.loadStats();
        debugPrint('PropertyListPage: After refresh - filteredProperties.length = ${provider.filteredProperties.length}');
      },
      child: provider.filteredProperties.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when empty
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6, // Make it scrollable
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.home,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchTerm.isNotEmpty || provider.filterStatus != 'all'
                              ? 'Try changing your search or filter'
                              : 'Add your first property to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Add refresh button for manual refresh
                        ElevatedButton.icon(
                          onPressed: () async {
                            debugPrint('PropertyListPage: Manual refresh button pressed');
                            await provider.loadProperties();
                            await provider.loadStats();
                            debugPrint('PropertyListPage: After manual refresh - filteredProperties.length = ${provider.filteredProperties.length}');
                          },
                          icon: const Icon(FontAwesomeIcons.rotate),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (provider.searchTerm.isEmpty && provider.filterStatus == 'all' && provider.isLandlord)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to add property
                              },
                              icon: const Icon(FontAwesomeIcons.plus),
                              label: const Text('Add New Property'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: provider.filteredProperties.length,
              itemBuilder: (context, index) {
                final property = provider.filteredProperties[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: property,
                    onView: () {
                      _navigateToPropertyDetail(property);
                    },
                    onEdit: () {
                      _navigateToEditProperty(property);
                    },
                    onStatusChanged: (newStatus) {
                      provider.updatePropertyStatus(
                        property.id,
                        newStatus,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  void _navigateToPropertyDetail(PropertyModel property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(property: property),
      ),
    );
  }

  void _navigateToEditProperty(PropertyModel property) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => EditPropertyPage(property: property),
    //   ),
    // );
  }
}
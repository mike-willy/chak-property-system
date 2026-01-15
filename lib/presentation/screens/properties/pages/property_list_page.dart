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
      backgroundColor: const Color(0xFF141725), // Dark background
      body: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(PropertyProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isLandlord ? 'My Properties' : 'Available',
                    style: const TextStyle(
                      fontSize: 28,
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
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              if (provider.isLandlord)
                IconButton(
                  icon: const Icon(FontAwesomeIcons.plus, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4E95FF), // Brand Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () {
                    // Navigate to add property
                  },
                ),
            ],
          ),
          if (provider.isLandlord) ...[
            const SizedBox(height: 24),
            _buildStatsRow(provider),
          ],
           const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PropertyProvider provider) {
    if (provider.isTenant) return const SizedBox.shrink(); // Hide stats for tenants

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
      ),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterSection(PropertyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235), // Dark Surface
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: TextEditingController(text: provider.searchTerm),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search properties...',
                prefixIcon: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                suffixIcon: provider.searchTerm.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          FontAwesomeIcons.xmark,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          provider.setSearchTerm('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                hintStyle: TextStyle(color: Colors.grey.shade600),
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
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: 'Occupied',
                  value: 'occupied',
                  icon: FontAwesomeIcons.userCheck,
                  provider: provider,
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: 'Vacant',
                  value: 'vacant',
                  icon: FontAwesomeIcons.doorClosed,
                  provider: provider,
                ),
                const SizedBox(width: 10),
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
    return Material(
       color: Colors.transparent,
       child: InkWell(
        onTap: () => provider.setFilterStatus(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4E95FF) : const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF4E95FF) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesList(PropertyProvider provider) {
    // Debug output
    // debugPrint('PropertyListPage: filteredProperties.length = ${provider.filteredProperties.length}');

    // Show error if there's an error and no properties
    if (provider.error != null && provider.properties.isEmpty && !provider.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.triangleExclamation,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
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
                icon: const Icon(FontAwesomeIcons.rotate, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF4E95FF),
                   foregroundColor: Colors.white,
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
            CircularProgressIndicator(color: Color(0xFF4E95FF)),
            SizedBox(height: 16),
            Text(
              'Loading properties...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Wrap everything in RefreshIndicator
    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadProperties();
        await provider.loadStats();
      },
      backgroundColor: const Color(0xFF1E2235),
      color: const Color(0xFF4E95FF),
      child: provider.filteredProperties.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                           padding: const EdgeInsets.all(24),
                           decoration: const BoxDecoration(
                             color: Color(0xFF1E2235),
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                            FontAwesomeIcons.house,
                            size: 48,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.searchTerm.isNotEmpty || provider.filterStatus != 'all'
                              ? 'Try changing your search or filter'
                              : 'Add your first property to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Add refresh button for manual refresh
                        ElevatedButton.icon(
                          onPressed: () async {
                             await provider.loadProperties();
                             await provider.loadStats();
                          },
                          icon: const Icon(FontAwesomeIcons.rotate, size: 16),
                          label: const Text('Refresh'),
                          style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF1E2235),
                             foregroundColor: Colors.white,
                             side: BorderSide(color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: provider.filteredProperties.length,
              itemBuilder: (context, index) {
                final property = provider.filteredProperties[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
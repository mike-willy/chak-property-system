import 'package:flutter/material.dart';
import '../../../data/models/property_model.dart';

class RecentActivity extends StatelessWidget {
  final List<PropertyModel> properties;
  final bool isLoading;

  const RecentActivity({
    super.key,
    required this.properties,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (properties.isEmpty) {
      return const Text('No recent activity.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...properties.map(
          (property) => ListTile(
            leading: property.images.isNotEmpty
                ? Image.network(
                    property.images.first,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.home),
            title: Text(property.title),
            subtitle: Text(
                'Updated: ${property.updatedAt.toString().split(' ')[0]}'),
            onTap: () {
              // Navigate to property detail if needed
            },
          ),
        ),
      ],
    );
  }
}

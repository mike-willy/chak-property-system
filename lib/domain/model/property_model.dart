class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String status;
  final String type;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.type,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'available',
      type: json['type'] ?? 'house',
      location: json['location'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      area: (json['area'] ?? 0).toDouble(),
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'status': status,
      'type': type,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
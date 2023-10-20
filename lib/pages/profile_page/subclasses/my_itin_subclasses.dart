class Location {
  final String name;
  final String category;
  final double latitude; // Add latitude field
  final double longitude; // Add longitude field

  Location({
    required this.name,
    required this.category,
    required this.latitude, // Initialize latitude
    required this.longitude, // Initialize longitude
  });

  @override
  String toString() {
    return 'Location(name: $name, category: $category, latitude: $latitude, longitude: $longitude)';
  }
}

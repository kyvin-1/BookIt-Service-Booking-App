class ServiceProvider {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final List<String> servicesOffered;
  final double hourlyRate;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.servicesOffered,
    required this.hourlyRate,
  });

  static String defaultImageForCategory(String name, [String? specialty]) {
    final text = '$name ${specialty ?? ''}'.toLowerCase();

    if (text.contains('plumb')) {
      return 'assets/providers/plumbing.jpg';
    }

    if (text.contains('clean')) {
      return 'assets/providers/homecleaning.jpg';
    }

    return '';
  }

  String get resolvedImageUrl {
    final trimmed = imageUrl.trim();

    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    return defaultImageForCategory(name, specialty);
  }

  bool get hasImage => resolvedImageUrl.isNotEmpty;
}

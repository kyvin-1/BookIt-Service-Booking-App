import 'package:flutter_test/flutter_test.dart';
import 'package:service_booking_app/models/provider_model.dart';

void main() {
  group('ServiceProvider image resolution', () {
    test('uses plumbing asset when image URL is empty', () {
      final provider = ServiceProvider(
        id: 'p1',
        name: 'John Doe Plumbing',
        specialty: 'Plumber',
        rating: 4.8,
        reviewCount: 12,
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        servicesOffered: const ['Pipe Repair'],
        hourlyRate: 75,
      );

      expect(provider.resolvedImageUrl, 'assets/providers/plumbing.jpg');
    });

    test('uses cleaning asset when image URL is empty', () {
      final provider = ServiceProvider(
        id: 'p2',
        name: 'Maria Home Cleaning',
        specialty: 'Cleaning',
        rating: 4.8,
        reviewCount: 12,
        imageUrl: '',
        latitude: 0,
        longitude: 0,
        servicesOffered: const ['Home Cleaning'],
        hourlyRate: 75,
      );

      expect(provider.resolvedImageUrl, 'assets/providers/homecleaning.jpg');
    });
  });
}

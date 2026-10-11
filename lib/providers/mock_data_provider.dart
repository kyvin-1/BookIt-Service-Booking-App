import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/provider_model.dart';
import '../models/appointment_model.dart';

final mockProvidersProvider = Provider<List<ServiceProvider>>((ref) {
  return [
    ServiceProvider(
      id: 'p1',
      name: 'John Doe Plumbing',
      specialty: 'Plumber',
      rating: 4.8,
      reviewCount: 124,
      imageUrl: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?auto=format&fit=crop&q=80&w=200',
      latitude: 40.7128,
      longitude: -74.0060,
      servicesOffered: ['Pipe Repair', 'Installation', 'Leak Detection'],
      hourlyRate: 75.0,
    ),
    ServiceProvider(
      id: 'p2',
      name: 'Sarah Hair Salon',
      specialty: 'Hair Stylist',
      rating: 4.9,
      reviewCount: 89,
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=200',
      latitude: 40.7142,
      longitude: -74.0064,
      servicesOffered: ['Haircut', 'Coloring', 'Styling'],
      hourlyRate: 50.0,
    ),
    ServiceProvider(
      id: 'p3',
      name: 'Mike Personal Training',
      specialty: 'Personal Trainer',
      rating: 4.7,
      reviewCount: 56,
      imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&q=80&w=200',
      latitude: 40.7150,
      longitude: -74.0050,
      servicesOffered: ['Weight Loss', 'Muscle Building', 'Nutrition'],
      hourlyRate: 60.0,
    ),
  ];
});

class AppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() {
    return [];
  }

  void addAppointment(Appointment appointment) {
    state = [...state, appointment];
  }

  void cancelAppointment(String id) {
    state = state.map((app) {
      if (app.id == id) {
        return Appointment(
          id: app.id,
          provider: app.provider,
          dateTime: app.dateTime,
          status: AppointmentStatus.cancelled,
        );
      }
      return app;
    }).toList();
  }
}

final appointmentsProvider = NotifierProvider<AppointmentsNotifier, List<Appointment>>(() {
  return AppointmentsNotifier();
});

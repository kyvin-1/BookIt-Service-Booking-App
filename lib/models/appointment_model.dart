import 'provider_model.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class Appointment {
  final String id;
  final ServiceProvider provider;
  final DateTime dateTime;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.provider,
    required this.dateTime,
    this.status = AppointmentStatus.pending,
  });
}

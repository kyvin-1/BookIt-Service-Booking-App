import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/provider_model.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final ServiceProvider provider;

  const BookingScreen({
    super.key,
    required this.provider,
  });

  @override
  ConsumerState<BookingScreen> createState() =>
      _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const Color primaryGreen = Color(0xFF1D8F5A);
  static const Color lightGreen = Color(0xFFE9F7EF);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color pageBackground = Color(0xFFF7FAF8);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;

  bool _loadingTimeSlots = false;
  bool _booking = false;

  Set<String> _bookedTimeSlots = {};

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  // =========================================================
  // DATE + TIME
  // =========================================================

  DateTime _combineDateAndTime(
    DateTime date,
    String time,
  ) {
    final parts = time.split(' ');
    final timePart = parts[0];
    final period = parts[1];

    final timeValues = timePart.split(':');

    int hour = int.parse(timeValues[0]);
    final minute = int.parse(timeValues[1]);

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  // =========================================================
  // DATE FORMATTERS
  // =========================================================

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  String _formatSelectedDate(DateTime date) {
    return '${_shortMonthName(date.month)} '
        '${date.day}, ${date.year}';
  }

  String _formatDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[date.weekday - 1];
  }

  // =========================================================
  // CHECK IF TIME HAS PASSED
  // =========================================================

  bool _isPastTimeSlot(
    DateTime date,
    String time,
  ) {
    final slotDateTime = _combineDateAndTime(
      date,
      time,
    );

    return slotDateTime.isBefore(DateTime.now());
  }

  // =========================================================
  // LOAD BOOKED TIME SLOTS
  // =========================================================

  Future<void> _loadBookedTimeSlots(
    DateTime date,
  ) async {
    setState(() {
      _loadingTimeSlots = true;
      _selectedTimeSlot = null;
      _bookedTimeSlots = {};
    });

    try {
      final bookedSlots =
          await BookingService().getBookedTimeSlots(
        providerId: widget.provider.id,
        date: date,
        timeSlots: _timeSlots,
      );

      if (!mounted) return;

      setState(() {
        _bookedTimeSlots = bookedSlots;
        _loadingTimeSlots = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _bookedTimeSlots = {};
        _loadingTimeSlots = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to check availability: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BOOK APPOINTMENT
  // =========================================================

  Future<void> _bookAppointment() async {
    if (_selectedDay == null ||
        _selectedTimeSlot == null) {
      return;
    }

    final selectedDateTime = _combineDateAndTime(
      _selectedDay!,
      _selectedTimeSlot!,
    );

    if (selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a future time slot.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_bookedTimeSlots.contains(
      _selectedTimeSlot,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This time slot is already booked.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _booking = true;
    });

    try {
      await BookingService().createBooking(
        providerId: widget.provider.id,
        providerName: widget.provider.name,
        service: widget.provider.specialty,
        dateTime: selectedDateTime,
      
      );
     await NotificationService.showBookingNotification(
       title: 'Booking Submitted',
       body: 'Your booking with ${widget.provider.name} has been submitted successfully.',
);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              20,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: primaryGreen,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your appointment with '
                  '${widget.provider.name} has been scheduled.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatSelectedDate(
                          _selectedDay!,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedTimeSlot!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _booking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (_selectedDay != null) {
        await _loadBookedTimeSlots(
          _selectedDay!,
        );
      }
    }
  }

  // =========================================================
  // PROVIDER HEADER
  // =========================================================

  Widget _buildProviderHeader() {
    final provider = widget.provider;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        4,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              width: 74,
              height: 74,
              child: provider.resolvedImageUrl.isNotEmpty
                  ? provider.resolvedImageUrl
                          .startsWith('http')
                      ? Image.network(
                          provider.resolvedImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _providerPlaceholder();
                          },
                        )
                      : Image.asset(
                          provider.resolvedImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return _providerPlaceholder();
                          },
                        )
                  : _providerPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking with',
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment:
                      WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.specialty,
                        style: const TextStyle(
                          fontSize: 10,
                          color: primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          provider.rating
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerPlaceholder() {
    return Container(
      color: lightGreen,
      child: const Icon(
        Icons.home_repair_service_rounded,
        color: primaryGreen,
        size: 32,
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CALENDAR
  // =========================================================

  Widget _buildCalendar() {
    final today = DateTime.now();

    final firstDay = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final lastDay = firstDay.add(
      const Duration(days: 90),
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.fromLTRB(
        8,
        7,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        availableGestures:
            AvailableGestures.horizontalSwipe,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: primaryGreen,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: primaryGreen,
          ),
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
          headerPadding:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: const TextStyle(
            color: secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: const TextStyle(
            color: secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(
            _selectedDay,
            day,
          );
        },
        onDaySelected: (
          selectedDay,
          focusedDay,
        ) {
          HapticFeedback.selectionClick();

          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedTimeSlot = null;
            _bookedTimeSlots = {};
          });

          _loadBookedTimeSlots(
            selectedDay,
          );
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(5),
          defaultTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
          weekendTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
          outsideTextStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade300,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          todayTextStyle: const TextStyle(
            color: primaryGreen,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: const BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: primaryGreen.withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
          ),
          tablePadding:
              const EdgeInsets.symmetric(
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SELECTED DATE
  // =========================================================

  Widget _buildSelectedDateCard() {
    if (_selectedDay == null) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.touch_app_rounded,
                color: Colors.grey.shade500,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                'Select a date to see available times.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected date',
                  style: TextStyle(
                    fontSize: 10,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDayName(_selectedDay!)} • '
                  '${_formatSelectedDate(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIME SLOTS
  // =========================================================

  Widget _buildTimeSlots() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.schedule_rounded,
          title: 'Choose a time',
          subtitle:
              'Select one available appointment slot.',
        ),
        if (_loadingTimeSlots)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32,
            ),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Checking availability...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth =
                  (constraints.maxWidth - 9) / 2;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _timeSlots.map((time) {
                    final isSelected =
                        _selectedTimeSlot == time;

                    final isBooked =
                        _bookedTimeSlots.contains(time);

                    final isPast =
                        _isPastTimeSlot(
                      _selectedDay!,
                      time,
                    );

                    return SizedBox(
                      width: slotWidth,
                      child: _buildTimeSlot(
                        time: time,
                        isSelected: isSelected,
                        isBooked: isBooked,
                        isPast: isPast,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTimeSlot({
    required String time,
    required bool isSelected,
    required bool isBooked,
    required bool isPast,
  }) {
    final disabled = isBooked || isPast;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();

              setState(() {
                _selectedTimeSlot =
                    isSelected ? null : time;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade100
              : isSelected
                  ? primaryGreen
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : isSelected
                    ? primaryGreen
                    : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.grey.shade200
                    : isSelected
                        ? Colors.white.withValues(
                            alpha: 0.16,
                          )
                        : lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                disabled
                    ? Icons.block_rounded
                    : isSelected
                        ? Icons.check_rounded
                        : Icons.access_time_rounded,
                size: 16,
                color: disabled
                    ? Colors.grey.shade400
                    : isSelected
                        ? Colors.white
                        : primaryGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: disabled
                          ? Colors.grey.shade500
                          : isSelected
                              ? Colors.white
                              : darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isBooked
                        ? 'Booked'
                        : isPast
                            ? 'Passed'
                            : isSelected
                                ? 'Selected'
                                : 'Available',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? Colors.grey.shade500
                          : isSelected
                              ? Colors.white.withValues(
                                  alpha: 0.85,
                                )
                              : secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BOOKING SUMMARY
  // =========================================================

  Widget _buildBookingSummary() {
    if (_selectedDay == null ||
        _selectedTimeSlot == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        22,
        16,
        16,
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow(
            icon: Icons.person_outline_rounded,
            label: 'Provider',
            value: widget.provider.name,
          ),
          const SizedBox(height: 11),
          _summaryRow(
            icon: Icons.home_repair_service_outlined,
            label: 'Service',
            value: widget.provider.specialty,
          ),
          const SizedBox(height: 11),
          _summaryRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _formatSelectedDate(
              _selectedDay!,
            ),
          ),
          const SizedBox(height: 11),
          _summaryRow(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _selectedTimeSlot!,
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Text(
                'Service rate',
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryText,
                ),
              ),
              const Spacer(),
              Text(
                '₱${widget.provider.hourlyRate.toInt()}/hr',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryGreen,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 57,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: darkText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: darkText,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildProviderHeader(),

            _buildSectionTitle(
              icon: Icons.calendar_month_rounded,
              title: 'Choose a date',
              subtitle:
                  'Select a date for your appointment.',
            ),

            _buildCalendar(),

            const SizedBox(height: 15),

            _buildSelectedDateCard(),

            _buildTimeSlots(),

            _buildBookingSummary(),
          ],
        ),
      ),

      // =====================================================
      // CONFIRM BUTTON
      // =====================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.07,
                ),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _selectedDay != null &&
                          _selectedTimeSlot != null &&
                          !_booking
                      ? _bookAppointment
                      : null,
              icon: _booking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline_rounded,
                    ),
              label: Text(
                _booking
                    ? 'Booking...'
                    : _selectedDay == null
                        ? 'Select a Date'
                        : _selectedTimeSlot == null
                            ? 'Select a Time'
                            : 'Confirm Booking',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.grey.shade300,
                disabledForegroundColor:
                    Colors.grey.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
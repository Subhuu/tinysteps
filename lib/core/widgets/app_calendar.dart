import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:tinysteps/core/constants/app_theme.dart';

class AppCalendar extends StatefulWidget {
  const AppCalendar({super.key});

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 📅 HEADER (Month + Year Display)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  );
                });
              },
            ),

            Text(
              DateFormat.yMMMM().format(_focusedDay),
              style: AppTextStyles.heading2,
            ),

            IconButton(
              icon: Icon(Icons.chevron_right, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  );
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 📅 CALENDAR
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,

          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          headerVisible: false, // we use custom header

          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary, // today highlight
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.danger,
            ),
            defaultTextStyle: AppTextStyles.bodySmall,
          ),

          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: AppTextStyles.labelBold,
            weekendStyle: AppTextStyles.labelBold.copyWith(
              color: AppColors.danger,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 📍 Selected Date Display
        Text(
          "Selected: ${DateFormat.yMMMd().format(_selectedDay)}",
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }
}

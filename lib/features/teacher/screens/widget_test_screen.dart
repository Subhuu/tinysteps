import 'package:flutter/material.dart';
import '../widgets/child_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/attendance_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

class WidgetTestScreen extends StatelessWidget {
  const WidgetTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5), // Sunrise background
      appBar: AppBar(
        title: const Text("Widget Testing"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// 🔶 Section Header
            const SectionHeader(
              title: "Section Header",
              actionText: "View All",
            ),

            const SizedBox(height: 20),

            /// 👶 Child Avatar
            const Text("Child Avatar"),
            const SizedBox(height: 10),
            const Row(
              children: [
                ChildAvatar(name: "Aarav Sharma"),
                SizedBox(width: 10),
                ChildAvatar(name: "Riya"),
              ],
            ),

            const SizedBox(height: 20),

            /// 🟢 Status Chips
            const Text("Status Chips"),
            const SizedBox(height: 10),
            const Row(
              children: [
                StatusChip(status: AttendanceStatus.checkedIn),
                SizedBox(width: 8),
                StatusChip(status: AttendanceStatus.checkedOut),
                SizedBox(width: 8),
                StatusChip(status: AttendanceStatus.absent),
              ],
            ),

            const SizedBox(height: 20),

            /// 📋 Attendance Cards
            const Text("Attendance Cards"),
            const SizedBox(height: 10),
            const AttendanceCard(
              childName: "Aarav Sharma",
              time: "8:30 AM",
              status: AttendanceStatus.checkedIn,
            ),
            const AttendanceCard(
              childName: "Riya Patel",
              time: "9:00 AM",
              status: AttendanceStatus.checkedOut,
            ),

            const SizedBox(height: 20),

            /// 📭 Empty State
            const Text("Empty State"),
            const SizedBox(height: 20),
            const EmptyState(message: "No children found"),
          ],
        ),
      ),
    );
  }
}

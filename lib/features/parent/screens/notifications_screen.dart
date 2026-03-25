import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _attendanceCheckIn = true;
  bool _attendanceCheckOut = true;
  bool _emergencyAlerts = true;
  bool _emergencyLockdown = false;
  bool _announcementsGeneral = true;
  bool _announcementsEvents = true;
  bool _announcementsNewsletters = false;

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Color(0xFFC0B0AA),
        ),
      ),
    );
  }

  Widget _buildSwitchCard(List<_SwitchItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              SwitchListTile(
                title: Text(
                  e.value.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                subtitle: e.value.subtitle != null
                    ? Text(
                        e.value.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0A09A),
                        ),
                      )
                    : null,
                value: e.value.value,
                onChanged: (v) {
                  setState(() => e.value.onChanged(v));
                },
                activeColor: const Color(0xFFF47C6A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 18,
                  endIndent: 18,
                  color: Color(0xFFEDE3DC),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF3EF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEDE3DC),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF2D2D2D),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionLabel('ATTENDANCE'),
              _buildSwitchCard([
                _SwitchItem(
                  title: 'Check-In Alerts',
                  subtitle: 'Notified when child checks in',
                  value: _attendanceCheckIn,
                  onChanged: (v) => _attendanceCheckIn = v,
                ),
                _SwitchItem(
                  title: 'Check-Out Alerts',
                  subtitle: 'Notified when child checks out',
                  value: _attendanceCheckOut,
                  onChanged: (v) => _attendanceCheckOut = v,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionLabel('EMERGENCY'),
              _buildSwitchCard([
                _SwitchItem(
                  title: 'Emergency Alerts',
                  subtitle: 'High priority emergency notifications',
                  value: _emergencyAlerts,
                  onChanged: (v) => _emergencyAlerts = v,
                ),
                _SwitchItem(
                  title: 'Lockdown Alerts',
                  subtitle: 'Facility lockdown notifications',
                  value: _emergencyLockdown,
                  onChanged: (v) => _emergencyLockdown = v,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionLabel('ANNOUNCEMENTS'),
              _buildSwitchCard([
                _SwitchItem(
                  title: 'General Announcements',
                  subtitle: 'Updates from the daycare',
                  value: _announcementsGeneral,
                  onChanged: (v) => _announcementsGeneral = v,
                ),
                _SwitchItem(
                  title: 'Events',
                  subtitle: 'Upcoming events and activities',
                  value: _announcementsEvents,
                  onChanged: (v) => _announcementsEvents = v,
                ),
                _SwitchItem(
                  title: 'Newsletters',
                  subtitle: 'Monthly newsletters',
                  value: _announcementsNewsletters,
                  onChanged: (v) => _announcementsNewsletters = v,
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchItem {
  final String title;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchItem({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

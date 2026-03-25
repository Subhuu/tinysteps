import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/account_menu_item.dart';
import 'personal_details_screen.dart';
import 'pickup_authorization_screen.dart';
import 'notifications_screen.dart';
import 'payments_screen.dart';
import 'support_help_screen.dart';
import 'app_settings_screen.dart';
import 'about_app_screen.dart';

class ParentSettingsScreen extends StatelessWidget {
  const ParentSettingsScreen({super.key});

  void _showQrBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE3DC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share this with the daycare for quick check-in',
              style: TextStyle(fontSize: 13, color: Color(0xFFB0A09A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3EF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 140,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hussain Smith — Parent ID #4821',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB0A09A),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static const _menuItems = [
    _MenuItem(
      Icons.person_outline,
      'Personal Details',
      'Phone number, Emergency contact',
      0,
    ),
    _MenuItem(
      Icons.shield_outlined,
      'Pickup Authorization',
      'Manage authorized persons',
      1,
    ),
    _MenuItem(
      Icons.notifications_none,
      'Notifications',
      'Attendance, Emergency, Announcements',
      2,
    ),
    _MenuItem(
      Icons.credit_card_outlined,
      'Payments',
      'Pending payments, History',
      3,
    ),
    _MenuItem(
      Icons.help_outline,
      'Support & Help',
      'Contact daycare, FAQ, Email',
      4,
    ),
    _MenuItem(
      Icons.settings_outlined,
      'App Settings',
      'Dark mode, Language',
      5,
    ),
    _MenuItem(Icons.info_outline, 'About App', 'Version v1.0.0', 6),
  ];

  void _navigate(BuildContext context, int index) {
    final destinations = <Widget>[
      const PersonalDetailsScreen(),
      const PickupAuthorizationScreen(),
      const NotificationsScreen(),
      const PaymentsScreen(),
      const SupportHelpScreen(),
      const AppSettingsScreen(),
      const AboutAppScreen(),
    ];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destinations[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF3EF),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Top bar ──────────────────────────────────────────
                    Row(
                      children: [
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const Spacer(),
                        // QR icon
                        // GestureDetector(
                        //   onTap: () => _showQrBottomSheet(context),
                        //   child: Container(
                        //     width: 40,
                        //     height: 40,
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       shape: BoxShape.circle,
                        //       border: Border.all(
                        //         color: const Color(0xFFEDE3DC),
                        //         width: 0.5,
                        //       ),
                        //     ),
                        //     child: const Icon(
                        //       Icons.qr_code_scanner_outlined,
                        //       size: 20,
                        //       color: Color(0xFF888888),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(width: 10),
                        // // Green "+" circle
                        // Container(
                        //   width: 40,
                        //   height: 40,
                        //   decoration: const BoxDecoration(
                        //     color: Color(0xFF4CAF50),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: const Icon(
                        //     Icons.add,
                        //     color: Colors.white,
                        //     size: 22,
                        //   ),
                        // ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── User header ───────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEDE3DC),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFBCFC9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'H',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFD85A30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Hussain Smith',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'hussain@smith.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Menu list ─────────────────────────────────────────
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _menuItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = _menuItems[i];
                        return AccountMenuItem(
                          icon: item.icon,
                          title: item.title,
                          subtitle: item.subtitle,
                          onTap: () => _navigate(context, item.index),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Log Out button ────────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFF47C6A),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFF47C6A),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF47C6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Floating bottom nav bar ────────────────────────────────
              // Positioned(
              //   left: 0,
              //   right: 0,
              //   bottom: 0,
              //   child: _BottomNavBar(),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav Bar ─────────────────────────────────────────────────────────

// class _BottomNavBar extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 20,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _NavItem(icon: Icons.home_outlined, label: 'Home', isActive: false),
//               _NavItem(icon: Icons.child_care_outlined, label: 'Children', isActive: false),
//               _NavItem(icon: Icons.check_circle_outline, label: 'Attendance', isActive: false),
//               _NavItem(icon: Icons.settings_outlined, label: 'Account', isActive: true),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isActive;

//   const _NavItem({
//     required this.icon,
//     required this.label,
//     required this.isActive,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (isActive) {
//       return Container(
//         height: 44,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(22),
//           gradient: const LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFFF47C6A), Color(0xFFE05CA0)],
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: Colors.white, size: 18),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: const Color(0xFFBBBBBB), size: 24),
//       ],
//     );
//   }
// }

// ── Menu item data model ───────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final int index;

  const _MenuItem(this.icon, this.title, this.subtitle, this.index);
}

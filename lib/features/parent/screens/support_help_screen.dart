import 'package:flutter/material.dart';

class SupportHelpScreen extends StatelessWidget {
  const SupportHelpScreen({super.key});

  static const _faqs = [
    'How do I update my child\'s information?',
    'How do I report an absence?',
    'How do I view payment receipts?',
    'Who should I contact in an emergency?',
  ];

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

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
      ),
      child: Column(
        children: [
          _buildContactRow(Icons.phone_outlined, 'Call Daycare', '+1 (555) 100-2000', false),
          const Divider(height: 1, thickness: 0.5, indent: 18, endIndent: 18, color: Color(0xFFEDE3DC)),
          _buildContactRow(Icons.email_outlined, 'Email Us', 'hello@tinysteps.com', true),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String detail, bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF888888)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0A09A),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
        ],
      ),
    );
  }

  Widget _buildFaqCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
      ),
      child: Column(
        children: _faqs.asMap().entries.map((e) {
          final isLast = e.key == _faqs.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                  ],
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
                    'Support & Help',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionLabel('CONTACT'),
              _buildContactCard(),
              const SizedBox(height: 24),
              _buildSectionLabel('FAQ'),
              _buildFaqCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

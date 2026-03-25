import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  static const _pending = [
    _PaymentItem(Icons.calendar_today_outlined, 'March Tuition', 'Due Mar 28', r'$450.00', false),
    _PaymentItem(Icons.lunch_dining_outlined, 'Meal Plan - March', 'Due Mar 25', r'$60.00', false),
  ];

  static const _history = [
    _PaymentItem(Icons.calendar_today_outlined, 'February Tuition', 'Paid Feb 1', r'$450.00', true),
    _PaymentItem(Icons.lunch_dining_outlined, 'Meal Plan - Feb', 'Paid Feb 1', r'$60.00', true),
    _PaymentItem(Icons.calendar_today_outlined, 'January Tuition', 'Paid Jan 3', r'$450.00', true),
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

  Widget _buildPaymentCard(List<_PaymentItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF3EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0A09A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.amount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item.isPaid
                            ? const Color(0xFF0F6E56)
                            : const Color(0xFFD85A30),
                      ),
                    ),
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
                    'Payments',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSectionLabel('PENDING'),
              _buildPaymentCard(_pending),
              const SizedBox(height: 24),
              _buildSectionLabel('HISTORY'),
              _buildPaymentCard(_history),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isPaid;
  const _PaymentItem(
    this.icon,
    this.title,
    this.subtitle,
    this.amount,
    this.isPaid,
  );
}

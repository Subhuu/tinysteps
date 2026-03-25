import 'package:flutter/material.dart';

class PickupAuthorizationScreen extends StatelessWidget {
  const PickupAuthorizationScreen({super.key});

  static const _persons = [
    _AuthPerson('Sara Smith', 'Spouse', true),
    _AuthPerson('James Smith', 'Grandfather', true),
    _AuthPerson('Lily Patel', 'Aunt', false),
    _AuthPerson('Omar Hassan', 'Family Friend', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF3EF),
      body: SafeArea(
        child: Padding(
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
                    'Pickup Authorization',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _persons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = _persons[i];
                    return _PersonCard(person: p);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C6A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add Authorized Person',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final _AuthPerson person;
  const _PersonCard({required this.person});

  String get _initials {
    final parts = person.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE3DC), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFBCFC9),
            child: Text(
              _initials,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD85A30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.relationship,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0A09A),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: person.isActive
                  ? const Color(0xFFE1F5EE)
                  : const Color(0xFFF1EFE8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              person.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: person.isActive
                    ? const Color(0xFF0F6E56)
                    : const Color(0xFF5F5E5A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPerson {
  final String name;
  final String relationship;
  final bool isActive;
  const _AuthPerson(this.name, this.relationship, this.isActive);
}

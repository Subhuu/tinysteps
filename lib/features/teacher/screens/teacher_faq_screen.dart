import 'package:flutter/material.dart';
import 'package:tinysteps/core/constants/app_theme.dart';
import 'package:tinysteps/core/theme/theme_ext.dart';

class TeacherFAQScreen extends StatelessWidget {
  const TeacherFAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "q": "How do I mark attendance?",
        "a": "Scan the child's QR code to mark check-in and check-out."
      },
      {
        "q": "What if QR code is not working?",
        "a": "Retry scanning or contact admin."
      },
      {
        "q": "Can I edit child details?",
        "a": "Only parents or admin can edit child details."
      },
      {
        "q": "How do I contact support?",
        "a": "Use email or WhatsApp from Help & Support."
      },
      {
        "q": "Why is my account pending?",
        "a": "Teacher accounts need admin approval."
      },
    ];

    return Scaffold(
      backgroundColor: context.colors.bgLight,
      appBar: AppBar(
        title: Text("FAQs", style: context.textStyles.heading2),
        backgroundColor: context.colors.bgLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return _FaqCard(
            question: faqs[index]["q"]!,
            answer: faqs[index]["a"]!,
          );
        },
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqCard({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool isOpen = false;

  final Color accentOrange = const Color(0xFFFF7A66);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isOpen
              ? accentOrange
              : context.colors.border.withValues(alpha: 0.5),
        ),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          setState(() => isOpen = !isOpen);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  /// Question
                  Expanded(
                    child: Text(
                      widget.question,
                      style: context.textStyles.labelBold.copyWith(
                        color: isOpen ? accentOrange : Colors.black,
                      ),
                    ),
                  ),

                  /// Arrow Animation
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: accentOrange,
                    ),
                  ),
                ],
              ),

              /// Answer Animation
              AnimatedCrossFade(
                firstChild: const SizedBox(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    widget.answer,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
                crossFadeState: isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

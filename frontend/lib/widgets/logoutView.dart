import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoggedOutView extends StatelessWidget {
  const LoggedOutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroSection(),
                const SizedBox(height: 28),
                _featuresSection(),
              ],
            ),
          ),

          // 👇 Bottom-left animated back action
          Positioned(
            left: 16,
            bottom: 16,
            child: JumpingBackToHome(
              onTap: () {
                Navigator.pop(context);
                // or: Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO SECTION
  // ============================================================

  Widget _heroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'You are not logged in',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Return to the home screen to continue exploring CareerCraft.',
          style: TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================

  Widget _featuresSection() {
    return Column(
      children: const [
        _FeatureRow(
          icon: FontAwesomeIcons.github,
          title: 'Access Your Repositories',
          subtitle:
              'Repository-specific chatbot, generate README files, LinkedIn posts, resume bullet points, and add repositories to favorites.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: FontAwesomeIcons.user,
          title: 'Access Your Profile',
          subtitle: 'View and analyze your GitHub profile data.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: FontAwesomeIcons.comments,
          title: 'Mock Interview',
          subtitle:
              'Start a mock interview with questions tailored to your specific repositories.',
        ),
      ],
    );
  }
}

// ===================================================================
// JUMPING BACK TO HOME BUTTON
// ===================================================================

class JumpingBackToHome extends StatefulWidget {
  final VoidCallback onTap;

  const JumpingBackToHome({Key? key, required this.onTap}) : super(key: key);

  @override
  State<JumpingBackToHome> createState() => _JumpingBackToHomeState();
}

class _JumpingBackToHomeState extends State<JumpingBackToHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _jump;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _jump = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _jump,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _jump.value),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: Color(0xFF4F46E5),
                ),
                SizedBox(width: 6),
                Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// FEATURE ROW
// ===================================================================

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FaIcon(icon, size: 18, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

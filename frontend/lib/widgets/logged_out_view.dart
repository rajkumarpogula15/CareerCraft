import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'footer/terms.dart';
import 'footer/privacy.dart';

class LoggedOutView extends StatelessWidget {
  final VoidCallback onLogin;

  const LoggedOutView({Key? key, required this.onLogin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroSection(),
            const SizedBox(height: 32),
            _featuresSection(),
            const Spacer(),
            _loginButton(context),
          ],
        ),
      ),
    );
  }

  // ---------------- HERO ----------------

  Widget _heroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'CareerCraft',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Your AI-powered developer companion.\n'
          'Understand, document, and grow from your code.',
          style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  // ---------------- FEATURES ----------------

  Widget _featuresSection() {
    return Column(
      children: const [
        _FeatureRow(
          icon: Icons.description_outlined,
          title: 'AI README Generator',
          subtitle: 'Generate production-ready README files instantly.',
        ),
        SizedBox(height: 14),
        _FeatureRow(
          icon: Icons.chat_bubble_outline,
          title: 'Repository Chatbot',
          subtitle: 'Ask questions and understand your codebase deeply.',
        ),
        SizedBox(height: 14),
        _FeatureRow(
          icon: Icons.work_outline,
          title: 'Career Portfolio',
          subtitle: 'Turn GitHub projects into resumes & portfolios.',
        ),
      ],
    );
  }

  // ---------------- LOGIN BUTTON ----------------

  Widget _loginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _showLoginSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white, // 🔑 FIX
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ---------------- LOGIN MODAL ----------------

  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LoginBottomSheet(onLogin: onLogin),
    );
  }
}

// ===================================================================
// ===================== LOGIN BOTTOM SHEET ===========================
// ===================================================================

class _LoginBottomSheet extends StatefulWidget {
  final VoidCallback onLogin;

  const _LoginBottomSheet({required this.onLogin});

  @override
  State<_LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<_LoginBottomSheet> {
  bool agreed = false;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showBottomPopup(context, const TermsPopup());
      };

    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showBottomPopup(context, const PrivacyPopup());
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _showBottomPopup(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }

  void _handleLogin() {
    Navigator.of(context).pop(); // close sheet
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign in to CareerCraft',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We use GitHub to securely access your repositories.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: agreed,
                onChanged: (v) => setState(() => agreed = v ?? false),
                activeColor: const Color(0xFF4F46E5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _privacyRecognizer,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: agreed ? _handleLogin : null,
              icon: const Icon(FontAwesomeIcons.github),
              label: const Text(
                'Continue with GitHub',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF24292F),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                disabledForegroundColor: Colors.white70,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// ===================== FEATURE ROW WIDGET ===========================
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
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
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

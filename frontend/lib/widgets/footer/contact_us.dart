import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPopup extends StatelessWidget {
  const ContactUsPopup({super.key});

  // --- ACTIONS ---
  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@careercraft.com',
      queryParameters: {'subject': 'Support Request'},
    );

    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _makeCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1234567890');

    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Text(
            "Contact Us",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Questions? We’re here to help.",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),

          const SizedBox(height: 24),

          // --- INFO SECTION ---
          _infoRow(
            icon: Icons.email_outlined,
            title: "Email",
            value: "support@careercraft.com",
          ),
          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.phone_outlined,
            title: "Phone",
            value: "+1 234 567 890",
          ),
          const SizedBox(height: 18),

          _infoRow(
            icon: Icons.access_time_outlined,
            title: "Support Hours",
            value: "Mon–Fri | 9 AM–6 PM",
          ),

          const SizedBox(height: 32),

          // --- ACTION BUTTONS ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendEmail,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Email Us",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _makeCall,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Call Now",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- INFO ROW (ICON PERFECTLY CENTERED) ---
  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Icon(icon, size: 22, color: Colors.black87)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

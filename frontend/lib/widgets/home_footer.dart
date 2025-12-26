import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'footer/social_button.dart';
import 'footer/footer_link.dart';
import 'footer/privacy.dart';
import 'footer/terms.dart';
import 'footer/faqs.dart';
import 'footer/contact_us.dart';
import 'footer/blog.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "CareerCraft",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Build your career with purpose.",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            /// LINKS
            Wrap(
              spacing: 20,
              children: const [
                FooterLink(label: "Privacy", popup: PrivacyPopup()),
                FooterLink(label: "Terms", popup: TermsPopup()),
                FooterLink(label: "FAQs", popup: FAQsPopup()),
                FooterLink(label: "Contact Us", popup: ContactUsPopup()),
                FooterLink(label: "Blog", popup: BlogPopup()),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialButton(
                  icon: FontAwesomeIcons.github,
                  tooltip: "GitHub",
                  onTap: () {
                    _launchUrl("https://github.com/careercraft");
                  },
                ),
                const SizedBox(width: 16),
                SocialButton(
                  icon: FontAwesomeIcons.linkedin,
                  tooltip: "LinkedIn",
                  onTap: () {
                    _launchUrl("https://www.linkedin.com/in/careercraft");
                  },
                ),
                const SizedBox(width: 16),
                SocialButton(
                  icon: FontAwesomeIcons.facebook,
                  tooltip: "Facebook",
                  onTap: () {
                    _launchUrl("https://www.facebook.com/careercraft");
                  },
                ),
                const SizedBox(width: 16),
                SocialButton(
                  icon: FontAwesomeIcons.instagram,
                  tooltip: "Instagram",
                  onTap: () {
                    _launchUrl("https://www.instagram.com/careercraft");
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),
            Divider(color: theme.dividerColor.withOpacity(0.3)),
            const SizedBox(height: 6),
            Text(
              "© 2025 CareerCraft • v1.0.0",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

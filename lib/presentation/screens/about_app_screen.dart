import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            Row(
              children: [
                CircleIconButton(
                  back: true,
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                const Text(
                  AppStrings.aboutApp,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _AppHero(),
            const SizedBox(height: 16),
            const _InfoCard(
              icon: Icons.auto_awesome_outlined,
              title: AppStrings.appValueTitle,
              description: AppStrings.appValueDescription,
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              icon: Icons.groups_outlined,
              title: AppStrings.appAudienceTitle,
              description: AppStrings.appAudienceDescription,
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              icon: Icons.shield_outlined,
              title: AppStrings.appPrivacyTitle,
              description: AppStrings.appPrivacyDescription,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/branding/atilearn_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.appVersion,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.appBusinessTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.appDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.8,
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: context.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    height: 1.8,
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

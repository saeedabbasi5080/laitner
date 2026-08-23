import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  static const _githubUrl = 'https://github.com/saeedabbasi5080';
  static const _telegramUrl = 'https://t.me/saeid_abbasi_dev';

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

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
                  AppStrings.aboutDeveloper,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
                boxShadow: AppShadows.card(context),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 36,
                      color: context.accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.developerName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.developerTitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppStrings.developerDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.8, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionLabel(AppStrings.contactDeveloper),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.email_outlined,
                    title: AppStrings.sendEmail,
                    subtitle: AppStrings.developerEmail,
                    onTap: () => _openEmail(context),
                  ),
                  Divider(height: 1, color: colors.border),
                  _ContactTile(
                    icon: Icons.send_outlined,
                    title: AppStrings.telegram,
                    subtitle: _telegramUrl.isEmpty
                        ? AppStrings.telegramNotConfigured
                        : _telegramUrl,
                    onTap: _telegramUrl.isEmpty
                        ? null
                        : () => _openUrl(context, Uri.parse(_telegramUrl)),
                  ),
                  Divider(height: 1, color: colors.border),
                  _ContactTile(
                    icon: Icons.code_outlined,
                    title: AppStrings.github,
                    subtitle: AppStrings.developerGithub,
                    onTap: () => _openUrl(context, Uri.parse(_githubUrl)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppStrings.developerEmail,
      query: _encodeQueryParameters({'subject': 'ارتباط درباره Atilearn'}),
    );
    await _openUrl(context, uri);
  }

  String _encodeQueryParameters(Map<String, String> parameters) {
    return parameters.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.linkOpenFailed)));
    }
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colors = context.recallColors;
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled ? context.accentColor : colors.mutedForeground,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 11, color: colors.mutedForeground),
      ),
      trailing: Icon(
        Icons.open_in_new,
        size: 18,
        color: enabled ? colors.mutedForeground : colors.border,
      ),
      onTap: onTap,
    );
  }
}

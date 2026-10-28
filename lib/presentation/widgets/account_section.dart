import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/screens/sign_in_screen.dart';
import 'package:recall/presentation/widgets/active_devices_section.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';
import 'package:recall/presentation/widgets/sync_section.dart';

/// The account row on the settings screen.
///
/// Shows one of three things, chosen by [AuthCubit] rather than by anything
/// decided here:
///
///  - a warning, when signed out
///  - a button to sign in, also when signed out
///  - the signed-in number, and a way out
///
/// The warning is the reason this section exists. Signing in is optional and the
/// app is fully usable without it, so this is a warning and not a prompt: it says
/// what is true — lose the device and the cards are gone — and does not pretend a
/// backup exists yet.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Nothing at all while the lookup runs. Showing "sign in" to someone who
        // is in fact signed in — or a warning that they cannot recover their
        // cards — during that window would be worse than showing a blank.
        if (state.status == AuthStatus.unknown) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel(AppStrings.account),
            const SizedBox(height: 8),
            if (state.shouldWarnAboutNoBackup) ...[
              _NoBackupWarning(
                onSignIn: () => _openSignIn(context),
              ),
              const SizedBox(height: 12),
            ],
            _AccountCard(
              state: state,
              accent: accent,
              onSignIn: () => _openSignIn(context),
              onSignOut: () => _confirmSignOut(context),
              onEditName: () => _editDisplayName(context, state.user!),
            ),
            // Decides for itself whether to render: it shows for somebody signed in,
            // and also for somebody who has just been signed out from elsewhere —
            // the case where there is no account left to explain what happened.
            const SizedBox(height: 24),
            const SyncSection(),
            // Only for somebody with an account. Without one there is nothing to
            // list, and the question it answers — is this open somewhere else? —
            // is not a question they have.
            if (state.isSignedIn) ...[
              const SizedBox(height: 24),
              const ActiveDevicesSection(),
            ],
          ],
        );
      },
    );
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SignInScreen(),
      ),
    );
  }

  /// Confirms before signing out.
  ///
  /// Not because anything is destroyed — it is not — but because signing out means
  /// giving up the only copy that could ever become a backup, and doing that by
  /// accident is worth one tap to undo.
  Future<void> _confirmSignOut(BuildContext context) async {
    final cubit = context.read<AuthCubit>();
    final colors = context.recallColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: Text(
          AppStrings.signOutWarning,
          style: TextStyle(fontSize: 14, height: 1.7, color: colors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Local only: no request. A user on a plane must be able to sign out.
    await cubit.signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.signOutDone)),
    );
  }

  Future<void> _editDisplayName(BuildContext context, AuthUser user) async {
    final cubit = context.read<AuthCubit>();
    final controller = TextEditingController(text: user.displayName ?? '');

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.profileName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          maxLength: 60,
          decoration: const InputDecoration(hintText: AppStrings.profileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.close),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text(AppStrings.profileSave),
          ),
        ],
      ),
    );

    controller.dispose();

    // A null result means the dialog was dismissed, which is not an empty name.
    // Treating it as one would let a stray tap clear somebody's name.
    if (name == null) return;

    await cubit.setDisplayName(name);
    if (!context.mounted) return;

    final error = cubit.state.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error != null && error.failure == AuthFailure.unexpected
              ? error.message
              : AppStrings.profileSaved,
        ),
      ),
    );
  }
}

/// The warning shown to someone who has not signed in.
///
/// One sentence of substance, one of reassurance. Not more: a warning the user
/// has to dismiss every time they open settings becomes noise, and noise is how
/// warnings end up ignored.
class _NoBackupWarning extends StatelessWidget {
  const _NoBackupWarning({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 20, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.notSignedInWarning,
                  style: TextStyle(fontSize: 13, height: 1.8, color: colors.card),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: context.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                AppStrings.signIn,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card itself: who is signed in, or how to do so.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.state,
    required this.accent,
    required this.onSignIn,
    required this.onSignOut,
    required this.onEditName,
  });

  final AuthState state;
  final Color accent;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    if (!state.isSignedIn) {
      return Container(
        decoration: _decoration(context),
        child: ListTile(
          leading: Icon(Icons.person_outline, color: accent),
          title: const Text(AppStrings.signIn),
          subtitle: const Text(AppStrings.notSignedInWarningShort),
          trailing: const Icon(Icons.chevron_right),
          onTap: onSignIn,
        ),
      );
    }

    final user = state.user!;

    return Container(
      decoration: _decoration(context),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Text(
                user.label.characters.first,
                style: TextStyle(color: accent, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(
              user.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              // Says whether the server has confirmed the session this launch.
              // Without that, an offline launch and a live one look identical, and
              // the user cannot tell a stale account tile from a current one.
              state.verified
                  ? user.phoneNumber
                  : '${user.phoneNumber} · ${AppStrings.notSignedInWarningShort}',
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.mutedForeground),
              color: colors.card,
              onSelected: (value) {
                if (value == 'name') onEditName();
                if (value == 'out') onSignOut();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'name',
                  child: Text(AppStrings.profileName),
                ),
                PopupMenuItem(
                  value: 'out',
                  child: Text(AppStrings.signOut),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.cloud_done_outlined, size: 20),
            title: Text(
              AppStrings.backupComingSoon,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  /// The same card treatment the rest of the settings screen uses.
  ///
  /// Repeated rather than extracted because the decoration is four lines of theme
  /// lookup, and a helper that only ever wraps those four lines is a name to look
  /// up rather than code to read.
  BoxDecoration _decoration(BuildContext context) {
    final colors = context.recallColors;
    return BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.border),
      boxShadow: AppShadows.card(context),
    );
  }
}

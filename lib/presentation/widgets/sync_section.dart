import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/blocs/sync/sync_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Whether the user's work is on the server, and a way to put it there.
///
/// Renders for somebody who is signed in, and also for somebody who has just been
/// signed out from elsewhere — which is the case that matters most, because there
/// is no account left to explain what happened. Without that, the app would simply
/// appear to have forgotten the user.
class SyncSection extends StatefulWidget {
  const SyncSection({super.key, this.cubit});

  /// Supplied by a test, or resolved from the locator.
  final SyncCubit? cubit;

  @override
  State<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<SyncSection> {
  late final SyncCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? sl<SyncCubit>();
    // Local only, no network: what is already known is shown before anything is
    // asked of a server.
    _cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _SyncView(),
    );
  }
}

class _SyncView extends StatelessWidget {
  const _SyncView();

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthCubit>().state.isSignedIn;
    final state = context.watch<SyncCubit>().state;

    if (!signedIn && !state.signedOutElsewhere) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(AppStrings.syncTitle),
        const SizedBox(height: 8),

        // Gated on *not* being signed in as well as on the flag. The flag outlives
        // the sign-out it describes, so a stale one would otherwise tell somebody
        // who has since signed in that they had been removed.
        if (!signedIn && state.signedOutElsewhere)
          const _SignedOutElsewhere()
        else ...[
          Text(
            AppStrings.syncHint,
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: context.recallColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          _SyncCard(state: state),
        ],
      ],
    );
  }
}

/// What the user is told after being signed out from somewhere else.
///
/// Its own block rather than a line of error text, because it is not a failure
/// they can retry — it is a change of state they have to act on, and the action is
/// signing in again.
class _SignedOutElsewhere extends StatelessWidget {
  const _SignedOutElsewhere();

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.link_off, size: 20, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.syncDeviceRemoved,
              style: TextStyle(fontSize: 13, height: 1.8, color: colors.card),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = context.accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                state.hasPending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                size: 20,
                color: state.hasPending ? AppColors.danger : accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.isRunning ? AppStrings.syncRunning : syncStatusLine(state),
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                ),
              ),
            ],
          ),

          // Only when there is something waiting. A permanent "0 reviews pending"
          // is a line the user stops reading.
          if (state.hasPending) ...[
            const SizedBox(height: 10),
            Text(
              AppStrings.syncPendingSave(state.pendingReviews),
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],

          if (state.status == SyncStatus.failed) ...[
            const SizedBox(height: 10),
            Text(
              state.error ?? AppStrings.syncFailed,
              style: TextStyle(fontSize: 12, height: 1.7, color: AppColors.danger),
            ),
          ],

          const SizedBox(height: 14),
          _SyncButton(
            label: AppStrings.syncNow,
            busy: state.isRunning,
            onPressed: context.read<SyncCubit>().run,
          ),
        ],
      ),
    );
  }

  /// When the last sync was, in words.
  ///
  /// Local time, unlike the device list: this timestamp is written by this device's
  /// own clock, so comparing it with `DateTime.now()` is the right thing. The
  /// device list compares the *server's* clock and works in UTC for that reason.
  static String syncStatusLine(SyncState state) {
    final last = state.lastSyncedAt;
    if (last == null) return AppStrings.syncNeverRun;

    final elapsed = DateTime.now().difference(last);
    if (elapsed.isNegative || elapsed.inMinutes < 1) {
      return AppStrings.syncLastJustNow;
    }
    if (elapsed.inMinutes < 60) {
      return AppStrings.syncLastMinutes(elapsed.inMinutes);
    }
    if (elapsed.inHours < 24) {
      return AppStrings.syncLastHours(elapsed.inHours);
    }
    return AppStrings.syncLastDays(elapsed.inDays);
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}

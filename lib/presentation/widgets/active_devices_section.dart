import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/devices/active_devices_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Where the account is signed in, and getting out of one of those places.
///
/// Only ever built for somebody who is signed in — it is placed inside the account
/// block, which already knows. Nothing here is shown to a user without an account,
/// because there would be nothing to show and the question it answers ("is this
/// open somewhere else?") is not one they have.
class ActiveDevicesSection extends StatefulWidget {
  const ActiveDevicesSection({super.key, this.cubit});

  /// Supplied by a test, or resolved from the locator.
  ///
  /// A parameter rather than reaching straight for the singleton, so the section
  /// can be rendered against a list without a container — the same reason the
  /// sign-in screen takes one.
  final ActiveDevicesCubit? cubit;

  @override
  State<ActiveDevicesSection> createState() => _ActiveDevicesSectionState();
}

class _ActiveDevicesSectionState extends State<ActiveDevicesSection> {
  late final ActiveDevicesCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Read from the locator rather than created here: it is a singleton, and a
    // second one would mean two lists that disagreed after a sign-out.
    _cubit = widget.cubit ?? sl<ActiveDevicesCubit>();
    // Re-read on every open, because the whole value of this screen is that it is
    // current. Not awaited: the interface shows a loading line until it arrives.
    _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _ActiveDevicesView(),
    );
  }
}

class _ActiveDevicesView extends StatelessWidget {
  const _ActiveDevicesView();

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final state = context.watch<ActiveDevicesCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(AppStrings.activeDevices),
        const SizedBox(height: 8),
        Text(
          AppStrings.activeDevicesHint,
          style: TextStyle(fontSize: 12, height: 1.7, color: colors.mutedForeground),
        ),
        const SizedBox(height: 12),

        // Only once there is something to compare. The condition lives in the
        // state, where it is tested without a widget.
        if (state.anotherDeviceIsNewer) ...[
          const _OtherDeviceWarning(),
          const SizedBox(height: 12),
        ],

        if (state.hasFailed)
          _LoadFailed(message: state.error, onRetry: context.read<ActiveDevicesCubit>().load)
        else if (!state.hasLoaded)
          const _Loading()
        else
          _DeviceList(state: state, onSignOut: context.read<ActiveDevicesCubit>().signOut),
      ],
    );
  }
}

/// The warning for someone whose account is open elsewhere.
///
/// Deliberately narrow about what is at risk. Study progress cannot be lost —
/// reviews merge — so saying otherwise would be a scare the user learns to
/// dismiss, and a dismissed warning protects nobody.
class _OtherDeviceWarning extends StatelessWidget {
  const _OtherDeviceWarning();

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.devices_other, size: 20, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.otherDeviceInUse,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.recallColors.card,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.otherDeviceInUseHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    color: context.recallColors.card,
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

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.state, required this.onSignOut});

  final ActiveDevicesState state;
  final Future<void> Function(String deviceId) onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    if (state.devices.isEmpty) {
      return Text(
        AppStrings.noOtherDevices,
        style: TextStyle(fontSize: 12, color: colors.mutedForeground),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        children: [
          for (var index = 0; index < state.devices.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.border),
            _DeviceRow(
              device: state.devices[index],
              enabled: !state.busy,
              onSignOut: onSignOut,
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.enabled,
    required this.onSignOut,
  });

  final AuthDevice device;
  final bool enabled;
  final Future<void> Function(String deviceId) onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = context.accentColor;

    return ListTile(
      leading: Icon(
        device.current ? Icons.phone_iphone : Icons.devices,
        color: device.current ? accent : colors.mutedForeground,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              device.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: device.current ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (device.current) ...[
            const SizedBox(width: 8),
            _CurrentBadge(accent: accent),
          ],
        ],
      ),
      subtitle: Text(
        lastUsedLabel(device.lastSeenAt),
        style: TextStyle(fontSize: 12, color: colors.mutedForeground),
      ),
      trailing: device.current
          ? null
          : IconButton(
              icon: const Icon(Icons.link_off, size: 20),
              color: AppColors.danger,
              tooltip: AppStrings.signOutDevice,
              onPressed: enabled ? () => _confirm(context) : null,
            ),
    );
  }

  /// Confirms, because the device is not here to be asked and the user cannot
  /// undo it from this screen.
  Future<void> _confirm(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOutDeviceConfirm),
        content: Text(
          AppStrings.signOutDeviceWarning,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: dialogContext.recallColors.mutedForeground,
          ),
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

    if (proceed != true) return;

    await onSignOut(device.deviceId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.deviceSignedOut)),
    );
  }
}

/// Marks the device the user is holding.
class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        AppStrings.thisDevice,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message ?? AppStrings.devicesLoadFailed,
            style: const TextStyle(fontSize: 12, height: 1.7, color: AppColors.danger),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}

/// How long ago a device was last used, in words.
///
/// Compares in UTC on purpose. The server's clock is what these timestamps are,
/// and a local timezone applied to them would make "3 hours ago" wrong by exactly
/// the offset.
String lastUsedLabel(DateTime? when) {
  if (when == null) return AppStrings.deviceNeverSeen;

  final elapsed = DateTime.now().toUtc().difference(when.toUtc());
  if (elapsed.isNegative || elapsed.inMinutes < 1) {
    return AppStrings.deviceLastUsedJustNow;
  }
  if (elapsed.inMinutes < 60) {
    return AppStrings.deviceLastUsedMinutes(elapsed.inMinutes);
  }
  if (elapsed.inHours < 24) {
    return AppStrings.deviceLastUsedHours(elapsed.inHours);
  }
  return AppStrings.deviceLastUsedDays(elapsed.inDays);
}

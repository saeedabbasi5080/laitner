part of 'active_devices_cubit.dart';

/// Where the list has got to.
enum ActiveDevicesStatus {
  /// Nothing has been asked for yet.
  unknown,

  /// A request is in flight.
  loading,

  /// The list is present, possibly empty.
  loaded,

  /// The last attempt failed and [ActiveDevicesState.error] says why.
  failed,
}

class ActiveDevicesState extends Equatable {
  const ActiveDevicesState({
    this.status = ActiveDevicesStatus.unknown,
    this.devices = const [],
    this.error,
    this.busy = false,
  });

  final ActiveDevicesStatus status;

  /// Most recently used first, as the server sends them.
  final List<AuthDevice> devices;

  /// Ready to show, in Persian, or null.
  final String? error;

  /// Whether a sign-out is in flight, so the screen can disable its buttons
  /// rather than sending the same request twice.
  final bool busy;

  bool get hasLoaded => status == ActiveDevicesStatus.loaded;

  bool get hasFailed => status == ActiveDevicesStatus.failed;

  /// This device, when the server marked one.
  AuthDevice? get currentDevice {
    for (final device in devices) {
      if (device.current) return device;
    }
    return null;
  }

  /// Whether some other device has been used since this one.
  ///
  /// This is what the warning is built on, and it is deliberately narrow. False
  /// when this device's own last use is unknown: a comparison that cannot be made
  /// cannot justify a warning, and a warning that cannot be justified is one the
  /// user learns to dismiss.
  bool get anotherDeviceIsNewer {
    final mine = currentDevice?.lastSeenAt;
    if (mine == null) return false;

    return devices.any((device) {
      final theirs = device.lastSeenAt;
      return !device.current && theirs != null && theirs.isAfter(mine);
    });
  }

  /// Whether anything is listed besides this device.
  bool get hasOtherDevices => devices.any((device) => !device.current);

  ActiveDevicesState copyWith({
    ActiveDevicesStatus? status,
    List<AuthDevice>? devices,
    String? error,
    bool? busy,
    bool clearError = false,
  }) {
    return ActiveDevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [status, devices, error, busy];
}

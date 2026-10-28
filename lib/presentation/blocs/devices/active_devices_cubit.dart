import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/device_remote.dart';

part 'active_devices_state.dart';

/// Where an account is signed in, and getting out of one of those places.
///
/// The token is read from the store rather than held, for the same reason
/// `AuthCubit` keeps it out of its state: a bloc's state is printed in errors,
/// compared for equality and kept for the life of the app, and none of that should
/// apply to a credential.
class ActiveDevicesCubit extends Cubit<ActiveDevicesState> {
  ActiveDevicesCubit({
    required DeviceRemote remote,
    required AuthTokenStore tokenStore,
  })  : _remote = remote,
        _tokenStore = tokenStore,
        super(const ActiveDevicesState());

  final DeviceRemote _remote;
  final AuthTokenStore _tokenStore;

  /// Re-reads the list.
  ///
  /// Never throws: a failure lands in the state so the screen can say what
  /// happened and offer to try again. This runs when settings is opened, and a
  /// settings screen that crashes on a dropped connection is worse than one that
  /// says it could not load.
  Future<void> load() async {
    emit(state.copyWith(status: ActiveDevicesStatus.loading, clearError: true));

    final token = await _token();
    if (token == null) {
      // No account, so no devices. Not an error: signing in is optional and an
      // empty list is the truthful answer.
      emit(state.copyWith(status: ActiveDevicesStatus.loaded, devices: const []));
      return;
    }

    try {
      final found = await _remote.listDevices(token);
      emit(state.copyWith(status: ActiveDevicesStatus.loaded, devices: found));
    } on AuthError catch (error) {
      emit(state.copyWith(status: ActiveDevicesStatus.failed, error: error.message));
    }
  }

  /// Signs one device out, then re-reads the list.
  ///
  /// Re-read rather than removing the row locally: the server is the one that
  /// decides, and a list that disagreed with it would show a device as gone that
  /// is still able to sync.
  Future<void> signOut(String deviceId) async {
    if (state.busy) return;

    final token = await _token();
    if (token == null) return;

    emit(state.copyWith(busy: true, clearError: true));
    try {
      await _remote.signOutDevice(accessToken: token, deviceId: deviceId);
      emit(state.copyWith(busy: false));
      await load();
    } on AuthError catch (error) {
      emit(state.copyWith(
        busy: false,
        status: ActiveDevicesStatus.failed,
        error: error.message,
      ));
    }
  }

  Future<String?> _token() async {
    try {
      return (await _tokenStore.read())?.accessToken;
    } catch (error) {
      // Storage that will not open is indistinguishable, from here, from having
      // no session — and the screen has nothing useful to do with the difference.
      return null;
    }
  }
}

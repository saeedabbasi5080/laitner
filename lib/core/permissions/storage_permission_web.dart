/// Web does not require storage runtime permissions for file picking.
Future<bool> ensureStoragePermissionForFileAccess() async => true;

Future<bool> isStoragePermissionPermanentlyDenied() async => false;

Future<void> openStoragePermissionSettings() async {}

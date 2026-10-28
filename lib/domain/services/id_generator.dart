/// Making up the identifiers that new records are created with.
///
/// Its own thing because it has nothing to do with storage. It used to be a
/// method on `LocalDataSource`, which forced the presentation layer to depend on
/// the storage interface — five cubits pulled the whole interface in and only
/// ever called this one method. Storage is not identity, and once a second
/// backend exists (a local cache beside a server) neither of them is entitled to
/// decide what a new record is called.
///
/// Identifiers are minted on the device rather than asked of the server. A
/// record created with no network cannot wait for a round trip to learn its own
/// name: nothing else can reference it until it has one, and offline is a mode
/// this app supports rather than tolerates.
abstract interface class IdGenerator {
  /// A new identifier, unique across every device and session.
  String generateId();
}

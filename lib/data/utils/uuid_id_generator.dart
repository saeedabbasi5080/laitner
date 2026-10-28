import 'package:recall/domain/services/id_generator.dart';
import 'package:uuid/uuid.dart';

/// UUID v4 identifiers.
///
/// The implementation lives here rather than beside the interface so the domain
/// module keeps no dependency on the `uuid` package — the domain says what an
/// identifier is for, this says what one looks like.
///
/// v4 is 122 random bits, so two devices minting ids at the same moment without
/// talking to each other will not collide. That is the property that matters:
/// the ids have to be safe to merge later.
class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const _uuid = Uuid();

  @override
  String generateId() => _uuid.v4();
}

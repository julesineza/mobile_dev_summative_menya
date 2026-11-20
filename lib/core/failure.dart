/// A user-friendly error. Services convert Firebase exceptions into this so
/// providers and screens never deal with Firebase error codes.
class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

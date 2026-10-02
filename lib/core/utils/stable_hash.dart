/// FNV-1a 32-bit hash. Unlike [String.hashCode] it is stable across runs,
/// isolates and app versions, so it can derive persistent identifiers such as
/// local notification ids.
int stableHash31(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // Notification ids must fit a signed 32-bit int on Android.
  return hash & 0x7fffffff;
}

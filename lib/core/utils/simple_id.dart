class SimpleId {
  const SimpleId._();

  static String generate() {
    final DateTime now = DateTime.now().toUtc();
    return '${now.microsecondsSinceEpoch}';
  }
}

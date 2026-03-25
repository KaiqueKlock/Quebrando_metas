class TitleValidator {
  const TitleValidator._();

  static const int maxLength = 50;

  static String validate(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw const FormatException('Title cannot be empty');
    }

    if (trimmed.length > maxLength) {
      throw const FormatException('Title is too long');
    }

    return trimmed;
  }
}

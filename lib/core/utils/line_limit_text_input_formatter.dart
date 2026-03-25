import 'package:flutter/services.dart';

class LineLimitTextInputFormatter extends TextInputFormatter {
  const LineLimitTextInputFormatter({required this.maxLines})
    : assert(maxLines > 0);

  final int maxLines;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final int lineCount = _countLines(newValue.text);
    if (lineCount <= maxLines) {
      return newValue;
    }

    final String truncatedText = _truncateToMaxLines(newValue.text, maxLines);
    return TextEditingValue(
      text: truncatedText,
      selection: TextSelection.collapsed(offset: truncatedText.length),
      composing: TextRange.empty,
    );
  }

  int _countLines(String text) {
    if (text.isEmpty) return 1;
    return text.split(RegExp(r'\r\n?|\n')).length;
  }

  String _truncateToMaxLines(String text, int maxLines) {
    final List<String> lines = text.split(RegExp(r'\r\n?|\n'));
    if (lines.length <= maxLines) return text;
    return lines.take(maxLines).join('\n');
  }
}

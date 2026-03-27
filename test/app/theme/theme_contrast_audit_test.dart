@Tags(['smoke'])
import 'package:flutter_test/flutter_test.dart';
import 'package:quebrando_metas/app/theme/app_theme_settings.dart';
import 'package:quebrando_metas/app/theme/theme_contrast_audit.dart';

void main() {
  test('Theme color options should not be empty after WCAG filtering', () {
    expect(AppThemeSettings.colorOptions, isNotEmpty);
  });

  test('All selectable theme colors should pass WCAG contrast checks', () {
    for (final ThemeColorOption option in AppThemeSettings.colorOptions) {
      final ThemeContrastAuditResult result = ThemeContrastAudit.auditSeedColor(
        option.color,
      );
      final String failureMessage = result.failures
          .map(
            (failure) =>
                '${failure.label}: ${failure.ratio.toStringAsFixed(2)} < ${failure.minimumRatio.toStringAsFixed(1)}',
          )
          .join(', ');

      expect(
        result.passes,
        isTrue,
        reason: 'Cor ${option.label} reprovada: $failureMessage',
      );
    }
  });
}

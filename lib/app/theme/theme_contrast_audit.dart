import 'package:flutter/material.dart';
import 'package:quebrando_metas/app/theme/app_theme.dart';

class ContrastCheck {
  const ContrastCheck({
    required this.label,
    required this.ratio,
    required this.minimumRatio,
  });

  final String label;
  final double ratio;
  final double minimumRatio;

  bool get passes => ratio >= minimumRatio;
}

class ThemeContrastAuditResult {
  const ThemeContrastAuditResult({
    required this.seedColor,
    required this.checks,
  });

  final Color seedColor;
  final List<ContrastCheck> checks;

  bool get passes => checks.every((check) => check.passes);

  List<ContrastCheck> get failures =>
      checks.where((check) => !check.passes).toList(growable: false);
}

class ThemeContrastAudit {
  const ThemeContrastAudit._();

  static const double normalTextRatio = 4.5;
  static const double uiElementRatio = 3.0;

  static ThemeContrastAuditResult auditSeedColor(Color seedColor) {
    final ColorScheme lightScheme = AppTheme.light(seedColor).colorScheme;
    final ColorScheme darkScheme = AppTheme.dark(seedColor).colorScheme;

    final List<ContrastCheck> checks = <ContrastCheck>[
      ..._checksForScheme(mode: 'light', scheme: lightScheme),
      ..._checksForScheme(mode: 'dark', scheme: darkScheme),
    ];

    return ThemeContrastAuditResult(seedColor: seedColor, checks: checks);
  }

  static bool isSeedColorAccessible(Color seedColor) {
    return auditSeedColor(seedColor).passes;
  }

  static double contrastRatio(Color a, Color b) {
    final double luminanceA = a.computeLuminance();
    final double luminanceB = b.computeLuminance();
    final double lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
    final double darker = luminanceA > luminanceB ? luminanceB : luminanceA;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static List<ContrastCheck> _checksForScheme({
    required String mode,
    required ColorScheme scheme,
  }) {
    return <ContrastCheck>[
      _check(
        label: '$mode primary/onPrimary',
        background: scheme.primary,
        foreground: scheme.onPrimary,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode primaryContainer/onPrimaryContainer',
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode secondary/onSecondary',
        background: scheme.secondary,
        foreground: scheme.onSecondary,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode secondaryContainer/onSecondaryContainer',
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode tertiary/onTertiary',
        background: scheme.tertiary,
        foreground: scheme.onTertiary,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode surface/onSurface',
        background: scheme.surface,
        foreground: scheme.onSurface,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode error/onError',
        background: scheme.error,
        foreground: scheme.onError,
        minimumRatio: normalTextRatio,
      ),
      _check(
        label: '$mode outline/surface',
        background: scheme.surface,
        foreground: scheme.outline,
        minimumRatio: uiElementRatio,
      ),
    ];
  }

  static ContrastCheck _check({
    required String label,
    required Color background,
    required Color foreground,
    required double minimumRatio,
  }) {
    return ContrastCheck(
      label: label,
      ratio: contrastRatio(background, foreground),
      minimumRatio: minimumRatio,
    );
  }
}

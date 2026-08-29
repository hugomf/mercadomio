import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/theme.dart';

void main() {
  group('AppTheme typography', () {
    final theme = AppTheme.light;

    test('body and headline text use Inter', () {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Inter');
      expect(theme.textTheme.headlineSmall?.fontFamily, 'Inter');
    });

    test('label text uses Public Sans', () {
      expect(theme.textTheme.labelLarge?.fontFamily, 'Public Sans');
      expect(theme.textTheme.labelMedium?.fontFamily, 'Public Sans');
      expect(theme.textTheme.labelSmall?.fontFamily, 'Public Sans');
    });

    test('app bar title uses Inter', () {
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Inter');
    });

    test('elevated button label uses Public Sans', () {
      final style = theme.elevatedButtonTheme.style;
      final textStyle = style?.textStyle?.resolve({});
      expect(textStyle?.fontFamily, 'Public Sans');
    });
  });

  group('AppTheme.softShadow', () {
    test('is a subtle single-layer shadow tinted with onSurface', () {
      final shadow = AppTheme.softShadow;
      expect(shadow.length, 1);
      expect(shadow.first.blurRadius, 4);
      expect(shadow.first.offset, const Offset(0, 1));
      expect(shadow.first.color, const Color(0x0F181D16));
    });
  });
}

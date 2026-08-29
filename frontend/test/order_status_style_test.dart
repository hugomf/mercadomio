import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/order.dart';

void main() {
  group('OrderStatus design-token colors', () {
    test('completed uses secondary/secondaryContainer pair from mock', () {
      final s = OrderStatus.completed;
      expect(s.statusColor, const Color(0xFF446741));
      expect(s.statusBackgroundColor, const Color(0xFFC2EABA));
    });

    test('cancelled uses error/errorContainer pair from mock', () {
      final s = OrderStatus.cancelled;
      expect(s.statusColor, const Color(0xFFBA1A1A));
      expect(s.statusBackgroundColor, const Color(0xFFFFDAD6));
    });

    test('shipped uses primaryContainer pair from mock', () {
      final s = OrderStatus.shipped;
      expect(s.statusColor, const Color(0xFFF7FFF1));
      expect(s.statusBackgroundColor, const Color(0xFF268630));
    });

    test('paid uses tertiaryContainer pair', () {
      final s = OrderStatus.paid;
      expect(s.statusColor, const Color(0xFFFFFBFF));
      expect(s.statusBackgroundColor, const Color(0xFFC04C76));
    });

    test('pending uses neutral surface pair', () {
      final s = OrderStatus.pending;
      expect(s.statusColor, const Color(0xFF3F4A3D));
      expect(s.statusBackgroundColor, const Color(0xFFE5EADF));
    });
  });

  group('OrderStatus accent colors (safe on light surfaces)', () {
    test('every status has a dark-enough accent for white cards', () {
      for (final s in OrderStatus.values) {
        final accent = s.statusAccentColor;
        // Relative luminance must be low enough to read on white/near-white.
        expect(
          accent.computeLuminance(),
          lessThan(0.25),
          reason: '${s.displayName} accent too light for light surfaces',
        );
      }
    });

    test('accent values match design tokens', () {
      expect(OrderStatus.pending.statusAccentColor, const Color(0xFF3F4A3D));
      expect(OrderStatus.paid.statusAccentColor, const Color(0xFFA0335D));
      expect(OrderStatus.shipped.statusAccentColor, const Color(0xFF006B1B));
      expect(OrderStatus.completed.statusAccentColor, const Color(0xFF446741));
      expect(OrderStatus.cancelled.statusAccentColor, const Color(0xFFBA1A1A));
    });
  });

  group('raw Material palette ban', () {
    test('status colors no longer use raw Material swatches', () {
      final banned = <Color>{
        Colors.orange[600]!, Colors.blue[600]!, Colors.deepPurple[600]!,
        Colors.green[600]!, Colors.red[600]!,
      };
      for (final s in OrderStatus.values) {
        expect(banned.contains(s.statusColor), isFalse,
            reason: '${s.displayName} still uses a raw Material color');
        expect(banned.contains(s.statusBackgroundColor), isFalse,
            reason: '${s.displayName} bg still uses a raw Material color');
      }
    });
  });
}

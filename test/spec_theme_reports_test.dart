import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_buiness_product_traker/core/theme/stockmate_theme.dart';
import 'package:online_buiness_product_traker/core/common/widgets/stockmate_components.dart';

void main() {
  group('Themes Specification Tests', () {
    test('All six themes exist in registry with exact Master Color Matrix hex codes', () {
      expect(StockMateThemeMode.values.length, 6);

      // 1. Light
      final light = StockMateThemes.light;
      expect(light.name, "Light");
      expect(light.bg, const Color(0xFFF5F6FA));
      expect(light.surface, const Color(0xFFFFFFFF));
      expect(light.accent, const Color(0xFF4F6EF7));
      expect(light.success, const Color(0xFF10B981));
      expect(light.shadow, const Color(0x14000000)); // rgba(0,0,0,0.08)

      // 2. Dark (Default)
      final dark = StockMateThemes.dark;
      expect(dark.name, "Dark");
      expect(dark.bg, const Color(0xFF0F1117));
      expect(dark.surface, const Color(0xFF1C1F2E));
      expect(dark.accent, const Color(0xFF6C8EFF));
      expect(dark.success, const Color(0xFF34D399));
      expect(dark.shadow, const Color(0x66000000)); // rgba(0,0,0,0.4)

      // 3. Midnight Blue
      final midnight = StockMateThemes.midnight;
      expect(midnight.name, "Midnight Blue");
      expect(midnight.bg, const Color(0xFF060D1F));
      expect(midnight.accent, const Color(0xFF3B82F6));
      expect(midnight.success, const Color(0xFF22D3EE)); // cyan
      expect(midnight.shadow, const Color(0x99000000)); // rgba(0,0,0,0.6)

      // 4. Emerald
      final emerald = StockMateThemes.emerald;
      expect(emerald.name, "Emerald");
      expect(emerald.bg, const Color(0xFF021A10));
      expect(emerald.accent, const Color(0xFF10B981));
      expect(emerald.accentLight, const Color(0xFF042014));
      expect(emerald.successLight, const Color(0xFF042014)); // shared with accentLight

      // 5. AMOLED Black
      final amoled = StockMateThemes.amoled;
      expect(amoled.name, "AMOLED Black");
      expect(amoled.bg, const Color(0xFF000000));
      expect(amoled.nav, const Color(0xFF000000));
      expect(amoled.accent, const Color(0xFFFF4081)); // neon pink
      expect(amoled.shadow, const Color(0x0DFFFFFF)); // rgba(255,255,255,0.05)

      // 6. Sunset Orange
      final sunset = StockMateThemes.sunset;
      expect(sunset.name, "Sunset Orange");
      expect(sunset.bg, const Color(0xFF1A0800));
      expect(sunset.accent, const Color(0xFFF97316));
      expect(sunset.textMuted, const Color(0xFFF97316)); // matches accent
      expect(sunset.accentLight, const Color(0xFF1A0800)); // equals bg
    });

    test('Structural facts from Section 4.1 hold across themes', () {
      for (final mode in StockMateThemeMode.values) {
        final t = StockMateThemes.get(mode);
        // card equals surface in all six themes
        expect(t.card, t.surface);

        // nav equals surface in every theme except AMOLED Black
        if (mode == StockMateThemeMode.amoled) {
          expect(t.nav, const Color(0xFF000000));
          expect(t.surface, const Color(0xFF0A0A0A));
        } else {
          expect(t.nav, t.surface);
        }

        // chartBar[0] equals accent in all six themes
        expect(t.chartBar[0], t.accent);

        // chartBar has 5 items
        expect(t.chartBar.length, 5);
      }
    });

    test('Transparency suffixes logic per Section 6.3', () {
      final t = StockMateThemes.dark;
      final c33 = t.withHexSuffix(t.accent, '33');
      expect((c33.a * 255).round(), 51); // 20% opacity (51/255)

      final c44 = t.withHexSuffix(t.accent, '44');
      expect((c44.a * 255).round(), 68); // ~26.7% opacity (68/255)
    });

    test('Currency formatting fmt() works for USD and BDT per Appendix A', () {
      expect(fmt(37.5, 'USD'), '\$37.5');
      expect(fmt(37.5, 'BDT'), '৳37.5');
      expect(fmt(25980, 'USD'), '\$25,980');
      expect(fmt(7320, 'BDT'), '৳7,320');
    });
  });
}

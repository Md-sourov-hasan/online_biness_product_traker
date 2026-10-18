import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/stockmate_theme.dart';
import '../../utils/constants/colors.dart';
import '../../utils/sizer.dart';
import '../styles/global_text_style.dart';

/// Formats currency per specification:
/// $ for USD, ৳ for BDT; thousands separators; 0-2 decimals
String fmt(num amount, String currency) {
  final sym = currency == 'BDT' ? '৳' : (currency == 'USD' ? '\$' : '$currency ');
  final d = amount.toDouble();
  final isInt = d == d.roundToDouble();
  final formatter = isInt
      ? NumberFormat('#,##0', 'en_US')
      : NumberFormat('#,##0.##', 'en_US');
  return sym + formatter.format(d);
}

/// Standard StockMate Card Panel
/// Background: t.card, radius 16, padding 16, border 1px t.border, shadow 0 2px 12px t.shadow
class StockMateCard extends StatelessWidget {
  final Widget child;
  final ThemeTokens t;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const StockMateCard({
    super.key,
    required this.child,
    required this.t,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Mini Preview Tile (Variants S, M, L) per Themes Spec Section 7.4
enum PreviewVariant { S, M, L }

class ThemePreviewTile extends StatelessWidget {
  final ThemeTokens theme;
  final ThemeTokens activeTheme;
  final PreviewVariant variant;

  const ThemePreviewTile({
    super.key,
    required this.theme,
    required this.activeTheme,
    this.variant = PreviewVariant.M,
  });

  @override
  Widget build(BuildContext context) {
    final double size = variant == PreviewVariant.L
        ? 56
        : 40;
    final double radius = variant == PreviewVariant.L
        ? 14
        : 10;
    final Border border = variant == PreviewVariant.L
        ? Border.all(color: activeTheme.accent, width: 2)
        : (variant == PreviewVariant.S
            ? Border.all(color: activeTheme.border, width: 1)
            : Border.all(color: theme.border, width: 1));

    final double pad = variant == PreviewVariant.L ? 6 : (variant == PreviewVariant.S ? 5 : 4);
    final double gap = variant == PreviewVariant.L ? 4 : 3;
    final double h1 = variant == PreviewVariant.L ? 12 : (variant == PreviewVariant.S ? 9 : 8);
    final double h2 = variant == PreviewVariant.L ? 7 : 5;
    final double h3 = variant == PreviewVariant.L ? 7 : 5;
    final double barRadius = variant == PreviewVariant.L ? 4 : 3;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: h1,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(barRadius),
            ),
          ),
          SizedBox(height: gap),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: Container(
              height: h2,
              decoration: BoxDecoration(
                color: theme.success,
                borderRadius: BorderRadius.circular(barRadius),
              ),
            ),
          ),
          SizedBox(height: gap),
          FractionallySizedBox(
            widthFactor: 0.5,
            child: Container(
              height: h3,
              decoration: BoxDecoration(
                color: theme.warning,
                borderRadius: BorderRadius.circular(barRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// StockMate Sparkline Widget per Analytics Spec Section 4.1
/// Polyline stroke 2, polygon fill 15% opacity, min-max scaling with single-point guard
class StockMateSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double width;
  final double height;

  const StockMateSparkline({
    super.key,
    required this.data,
    required this.color,
    this.width = 120,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(width: width, height: height);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(data: data, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final max = data.reduce(math.max);
    final min = data.reduce(math.min);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final n = data.length;

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n <= 1 ? size.width / 2 : (i / (n - 1)) * size.width;
      final y = size.height - ((data[i] - min) / range) * size.height;
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }

    // Draw shaded area
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}

/// StockMate BarChart Widget per Analytics Spec Section 4.2 & Reports Appendix A
/// Bottom-aligned flex columns, height (v/max)*100%, min 4px, radius 4 top corners,
/// cycling palette colors[i % colors.length], textMuted 9px labels.
class StockMateBarChart extends StatelessWidget {
  final List<num> data;
  final List<String>? labels;
  final List<Color> colors;
  final double height;
  final ThemeTokens t;

  const StockMateBarChart({
    super.key,
    required this.data,
    this.labels,
    required this.colors,
    this.height = 110,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    final maxVal = data.map((e) => e.toDouble()).reduce(math.max);
    final effectiveMax = maxVal <= 0 ? 1.0 : maxVal;

    // Allocate 18px for labels row if provided, remainder for bars
    final hasLabels = labels != null && labels!.isNotEmpty;
    final plotHeight = hasLabels ? (height - 18).clamp(20.0, height) : height;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final val = data[i].toDouble();
          final barPct = (val / effectiveMax).clamp(0.0, 1.0);
          final barH = math.max(4.0, barPct * plotHeight);
          final barColor = colors[i % colors.length];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barH,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  if (hasLabels) ...[
                    const SizedBox(height: 4),
                    Text(
                      i < labels!.length ? labels![i] : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: t.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// StockMate DonutChart Widget per Analytics Spec Section 4.3 & Reports Appendix A
/// CustomPainter: SVG 120x120 geometry, radius 45, stroke 18, start -90 deg (12 o'clock),
/// clockwise segments in category order.
class StockMateDonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> data; // [{name: "Electronics", value: 42}]
  final List<Color> colors;
  final double size;

  const StockMateDonutChart({
    super.key,
    required this.data,
    required this.colors,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _DonutChartPainter(data: data, colors: colors),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final List<Color> colors;

  _DonutChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold<double>(0.0, (sum, d) => sum + (d['value'] as num).toDouble());
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 120.0;
    final radius = 45.0 * scale;
    final strokeWidth = 18.0 * scale;

    double currentAngle = -math.pi / 2; // -90 degrees = 12 o'clock

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['value'] as num).toDouble();
      final sweepAngle = (val / total) * 2 * math.pi;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.colors != colors;
}

/// StockMate NetBanner Component per Reports Spec Section 4.4
/// Background successLight / dangerLight, border 1.5px with alpha 44 (27% opacity),
/// left label 12px 700, sub-line 11px at 70% opacity, right amount 22px 900.
class StockMateNetBanner extends StatelessWidget {
  final double profit;
  final double exp;
  final String? label;
  final String currency;
  final ThemeTokens t;

  const StockMateNetBanner({
    super.key,
    required this.profit,
    required this.exp,
    this.label,
    this.currency = 'USD',
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final net = profit - exp;
    final isPositive = net >= 0;
    final mainColor = isPositive ? t.success : t.danger;
    final bgColor = isPositive ? t.successLight : t.dangerLight;
    final borderColor = t.withHexSuffix(mainColor, '44');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? 'NET PROFIT (after expenses)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gross ${fmt(profit, currency)} − Exp ${fmt(exp, currency)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: mainColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? "+" : ""}${fmt(net, currency)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: mainColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// StockMate Metric / Stat Card with smooth micro-animation & tactile ripple
class StockMateStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final ThemeTokens t;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StockMateStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.t,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: t.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: accentColor, size: 20.w),
                  ),
                  ?trailing,
                ],
              ),
              12.verticalSpace,
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getTextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: t.textSec,
                ),
              ),
              4.verticalSpace,
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getTextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: t.text,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                4.verticalSpace,
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getTextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: t.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// StockMate Badge / Chip for roles, statuses, and tags
class StockMateBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isSmall;

  const StockMateBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 7.w : 10.w,
        vertical: isSmall ? 3.h : 4.5.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 10.w : 13.w, color: color),
            4.horizontalSpace,
          ],
          Text(
            label,
            style: getTextStyle(
              fontSize: isSmall ? 10.sp : 11.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth StockMate Quick Action Button
class StockMateActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ThemeTokens t;
  final String? badge;

  const StockMateActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.t,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: t.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: color, size: 22.w),
                  ),
                  if (badge != null && badge!.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              8.verticalSpace,
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getTextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// StockMate Search Bar with clear icon and optional filter trigger
class StockMateSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final VoidCallback? onClear;
  final Widget? trailing;
  final ThemeTokens t;

  const StockMateSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    required this.hintText,
    this.onClear,
    this.trailing,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.input,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          12.horizontalSpace,
          Icon(Icons.search_rounded, color: t.textSec, size: 20.w),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: getTextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: t.text,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: getTextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: t.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                if (onClear != null) onClear!();
                if (onChanged != null) onChanged!('');
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(Icons.close_rounded, size: 18.w, color: t.textMuted),
              ),
            ),
          if (trailing != null) ...[
            trailing!,
            8.horizontalSpace,
          ],
        ],
      ),
    );
  }
}

/// StockMate Empty State
class StockMateEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final ThemeTokens t;

  const StockMateEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48.w, color: t.accent),
            ),
            16.verticalSpace,
            Text(
              title,
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            8.verticalSpace,
            Text(
              description,
              textAlign: TextAlign.center,
              style: getTextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: t.textSec,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              20.verticalSpace,
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// StockMate Section Header with optional action
class StockMateSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final ThemeTokens t;

  const StockMateSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: getTextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: t.text,
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: getTextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: t.accent,
              ),
            ),
          ),
      ],
    );
  }
}

/// Smooth StockMate Loading Spinner
class StockMateLoading extends StatelessWidget {
  final double? size;
  final Color? color;
  final ThemeTokens? t;

  const StockMateLoading({
    super.key,
    this.size,
    this.color,
    this.t,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? t?.accent ?? AppColors.primary;
    return Center(
      child: SizedBox(
        width: size ?? 28.w,
        height: size ?? 28.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
        ),
      ),
    );
  }
}

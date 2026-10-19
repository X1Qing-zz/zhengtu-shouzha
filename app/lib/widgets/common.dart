import 'package:flutter/material.dart';

import '../core/season_visuals.dart';
import '../core/theme.dart';

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = 22,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.shadow.withValues(alpha: c.isDark ? 0.28 : 0.055),
                  blurRadius: 28,
                  spreadRadius: -6,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: Material(
        color: gradient == null ? (color ?? c.surface) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: BorderSide(
            color: borderColor ?? c.line.withValues(alpha: c.isDark ? 0.9 : 0.65),
            width: 0.8,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(borderRadius: shape, gradient: gradient),
          child: InkWell(
            onTap: onTap,
            splashColor: c.accent.withValues(alpha: 0.06),
            highlightColor: c.accent.withValues(alpha: 0.03),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.trailing});

  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? SeasonVisuals.secondary(context.season, c);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 1,
          color: tone.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 7),
        Text(
          text.toUpperCase(),
          style: AppText.eyebrow(color: color ?? c.muted),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onAction,
    this.action,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Eyebrow(eyebrow!),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: AppText.serifStyle(size: 21, color: c.ink, height: 1.25),
                ),
              ],
            ),
          ),
          if (action != null)
            action!
          else if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: c.ink,
                backgroundColor: c.accentSoft.withValues(alpha: c.isDark ? 0.55 : 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: StadiumBorder(
                  side: BorderSide(color: c.accent.withValues(alpha: 0.22), width: 0.7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.ink)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 13),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.muted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: filled ? tone.withValues(alpha: c.isDark ? 0.2 : 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tone.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 11.5, color: tone),
            const SizedBox(width: 3.5),
          ],
          Text(
            label,
            style: AppText.sans(
              size: dense ? 10 : 11,
              weight: FontWeight.w600,
              color: tone,
              height: 1.2,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: c.isDark ? 0.16 : 0.09),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: tone),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.sunken.withValues(alpha: c.isDark ? 0.6 : 0.7),
              border: Border.all(color: c.line.withValues(alpha: 0.8)),
            ),
            child: Icon(icon, size: 30, color: c.muted),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.serifStyle(size: 19, color: c.ink),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 13, color: c.muted, height: 1.7),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.bg,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 1.8, color: c.bg),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 17, color: c.bg),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppText.sans(size: 14.5, weight: FontWeight.w600, color: c.bg, letterSpacing: 0.5)),
        ],
      ],
    );
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        disabledBackgroundColor: c.ink.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = tone ?? c.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: c.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 7),
          ],
          Text(label, style: AppText.sans(size: 13, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({
    super.key,
    required this.checked,
    required this.onTap,
    this.color,
    this.size = 24,
  });

  final bool checked;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = color ?? c.moss;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: checked ? tone : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: checked ? tone : c.line.withValues(alpha: 1),
                width: 1.5,
              ),
            ),
            child: AnimatedScale(
              scale: checked ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.check_rounded,
                size: size * 0.62,
                color: c.isDark ? const Color(0xFF14130F) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.background,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: background ?? c.line.withValues(alpha: 0.6),
        valueColor: AlwaysStoppedAnimation<Color>(color ?? c.accent),
      ),
    );
  }
}

class PillSelector extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.activeColors,
    this.dense = false,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final List<Color>? activeColors;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.sunken.withValues(alpha: c.isDark ? 0.55 : 0.62),
        borderRadius: BorderRadius.circular(dense ? 11 : 13),
        border: Border.all(color: c.line.withValues(alpha: 0.5), width: 0.7),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selected;
          final hasCustomColor = activeColors != null && i < activeColors!.length;
          final activeColor = hasCustomColor ? activeColors![i] : c.accentSoft;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(vertical: dense ? 6 : 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(dense ? 9 : 11),
                  border: active
                      ? Border.all(color: c.accent.withValues(alpha: 0.24), width: 0.8)
                      : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  options[i],
                  style: AppText.sans(
                    size: dense ? 11.5 : 12.5,
                    weight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? (hasCustomColor ? c.bg : c.ink) : c.muted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {  const FadeSlideIn({
    super.key,
    required this.child,
    this.offset = 16,
    this.duration = const Duration(milliseconds: 520),
  });

  final Widget child;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      decoration: BoxDecoration(
        color: c.line,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 8, 22, 24),
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.line.withValues(alpha: 0.9), width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              if (scrollable)
                Flexible(child: SingleChildScrollView(child: content))
              else
                content,
            ],
          ),
        ),
      ),
    );
  }
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.serifStyle(size: 23, color: c.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: AppText.sans(size: 12.5, color: c.muted)),
              ],
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
            style: IconButton.styleFrom(
              backgroundColor: c.sunken.withValues(alpha: 0.7),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}

Future<T?> showAppSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: child,
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = '确定',
  String cancelLabel = '再想想',
  bool destructive = false,
}) async {
  final c = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.serifStyle(size: 20, color: c.ink)),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(message, style: AppText.sans(size: 13.5, color: c.inkSoft, height: 1.7)),
            ],
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel, style: AppText.sans(size: 13.5, color: c.muted)),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: destructive ? c.terra : c.ink,
                    foregroundColor: destructive ? Colors.white : c.bg,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

void showAppSnack(BuildContext context, String message, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

InputDecoration fieldDecoration(
  BuildContext context, {
  String? hint,
  String? label,
  Widget? prefix,
  Widget? suffix,
  bool dense = false,
}) {
  final c = context.colors;
  return InputDecoration(
    hintText: hint,
    labelText: label,
    prefixIcon: prefix,
    suffixIcon: suffix,
    isDense: dense,
    filled: true,
    fillColor: c.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: dense ? 11 : 14),
    hintStyle: AppText.sans(size: 14, color: c.muted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: c.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: c.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: c.accent, width: 1.2),
    ),
  );
}

import 'package:flutter/material.dart';

import '../theme/restep_theme.dart';

/// 本家風ピルボタン: 太枠+ぼかし無しの下オフセット影+太字イタリック文字。
class StepnButton extends StatelessWidget {
  const StepnButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = RS.mint,
    this.textColor = RS.ink,
    this.fontSize = 20,
    this.height = 58,
    this.width,
    this.subLabel,
  });

  final String label;
  final String? subLabel;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double fontSize;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      label: label,
      button: true,
      enabled: !disabled,
      excludeSemantics: true,
      onTap: onTap,
      child: Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: RS.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: RS.ink, offset: Offset(0, 4), blurRadius: 0),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: RS.label(size: fontSize, color: textColor)),
              if (subLabel != null)
                Text(subLabel!,
                    style: RS.label(size: fontSize * 0.62, color: textColor)),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// 小さなピルバッジ(アイコン+テキスト)。
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = RS.white,
    this.textColor = RS.ink,
    this.borderColor,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
  });

  final String text;
  final Widget? icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? RS.ink, width: 1.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 5)],
          Text(text, style: RS.label(size: fontSize, color: textColor)),
        ],
      ),
    );
  }
}

/// アイコン+テキスト+プログレスバーのピル(エナジー/デイリー上限用)。
class ProgressPill extends StatelessWidget {
  const ProgressPill({
    super.key,
    required this.leading,
    required this.text,
    required this.progress,
    this.trailing,
    this.fillColor = RS.mint,
    this.background = RS.white,
    this.textColor = RS.ink,
  });

  final Widget leading;
  final String text;
  final String? trailing;
  final double progress;
  final Color fillColor;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RS.ink, width: 1.6),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Text(text, style: RS.label(size: 14, color: textColor)),
          const Spacer(),
          if (trailing != null)
            Text(trailing!,
                style: RS.label(size: 12, color: RS.grey, italic: false)),
        ],
      ),
    );
  }
}

/// 白カード(太枠+下オフセット影+大きな角丸)。
class StepnCard extends StatelessWidget {
  const StepnCard({
    super.key,
    required this.child,
    this.color = RS.white,
    this.radius = 28,
    this.padding = const EdgeInsets.all(16),
    this.borderWidth = 2.5,
    this.shadowOffset = 5,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets padding;
  final double borderWidth;
  final double shadowOffset;
  final VoidCallback? onTap;

  /// タップ可能カードのアクセシビリティ名。指定時は子のセマンティクスを
  /// 1つのボタンに束ねる(子にプログレスバー等があってもロールが混ざらない)。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: RS.border, width: borderWidth),
          boxShadow: [
            BoxShadow(
                color: RS.border,
                offset: Offset(0, shadowOffset),
                blurRadius: 0),
          ],
        ),
        child: child,
      ),
    );
    if (onTap != null && semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: true,
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// 属性アイコン(小さな色付き多角形バッジ)。
class AttrIcon extends StatelessWidget {
  const AttrIcon({super.key, required this.color, this.size = 16, this.icon});

  final Color color;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: RS.ink, width: 1.2),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.62, color: RS.white)
          : null,
    );
  }
}

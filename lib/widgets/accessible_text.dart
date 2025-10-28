import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

enum AccessibleTextStyle {
  title,
  subtitle,
  body,
  button,
  label,
  hint,
}

class AccessibleText extends StatelessWidget {
  final String text;
  final AccessibleTextStyle style;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AccessibleText(
    this.text, {
    super.key,
    required this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(accessibilityService),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  double _getFontSize(AccessibilityService accessibilityService) {
    switch (style) {
      case AccessibleTextStyle.title:
        return accessibilityService.titleSize;
      case AccessibleTextStyle.subtitle:
        return accessibilityService.subtitleSize;
      case AccessibleTextStyle.body:
        return accessibilityService.bodyTextSize;
      case AccessibleTextStyle.button:
        return accessibilityService.buttonTextSize;
      case AccessibleTextStyle.label:
        return accessibilityService.labelTextSize;
      case AccessibleTextStyle.hint:
        return accessibilityService.hintTextSize;
    }
  }
}

// Convenção de widgets com nomes mais claros
class TitleText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const TitleText(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.title,
      color: color,
      fontWeight: fontWeight,
      textAlign: textAlign,
    );
  }
}

class SubtitleText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const SubtitleText(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.subtitle,
      color: color,
      fontWeight: fontWeight,
      textAlign: textAlign,
    );
  }
}

class BodyText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final FontWeight? fontWeight;

  const BodyText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.body,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      fontWeight: fontWeight,
    );
  }
}

class ButtonText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;

  const ButtonText(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.button,
      color: color,
      fontWeight: fontWeight,
    );
  }
}

class LabelText extends StatelessWidget {
  final String text;
  final Color? color;

  const LabelText(
    this.text, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.label,
      color: color,
    );
  }
}

class HintText extends StatelessWidget {
  final String text;
  final Color? color;

  const HintText(
    this.text, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibleText(
      text,
      style: AccessibleTextStyle.hint,
      color: color,
    );
  }
}

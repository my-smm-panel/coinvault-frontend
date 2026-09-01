import 'package:flutter/material.dart';

class EarnCategory {
  final String title;
  final String subtitle;
  final String reward;
  final IconData icon;
  final List<Color> colors;

  const EarnCategory({
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.icon,
    required this.colors,
  });
}

class OfferItem {
  final String title;
  final String subtitle;
  final String reward;
  final String tag;
  final Color color;
  final String initials;

  const OfferItem({
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.tag,
    required this.color,
    required this.initials,
  });
}

class SurveyItem {
  final String duration;
  final String reward;

  const SurveyItem(this.duration, this.reward);
}

class QuickActionItem {
  final String title;
  final IconData icon;
  final List<Color> colors;

  const QuickActionItem({
    required this.title,
    required this.icon,
    required this.colors,
  });
}

class WithdrawMethodItem {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final String glyph;

  const WithdrawMethodItem({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.glyph,
  });
}

class ActivityItem {
  final String title;
  final String subtitle;
  final String amount;
  final String trailing;
  final List<Color> colors;
  final IconData icon;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.trailing,
    required this.colors,
    required this.icon,
  });
}

class ChallengeItem {
  final String title;
  final String progress;
  final double percent;
  final String reward;

  const ChallengeItem({
    required this.title,
    required this.progress,
    required this.percent,
    required this.reward,
  });
}

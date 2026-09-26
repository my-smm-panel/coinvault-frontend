import 'package:flutter/material.dart';

import 'offer_detail_screen.dart';

/// Paymentwall details use the same backend-backed offer detail presentation.
/// The caller may pass fields from the Paymentwall payload; absent fields are
/// intentionally omitted rather than estimated locally.
class PaymentwallDetailScreen extends StatelessWidget {
  final String offerId;
  final String provider;
  final String title;
  final int? coins;
  final String? description;
  final String? duration;
  final List<String>? requirements;
  final List<String>? goals;
  final List<String>? rules;
  final bool? isVariable;

  const PaymentwallDetailScreen({
    super.key,
    required this.offerId,
    required this.provider,
    required this.title,
    this.coins,
    this.description,
    this.duration,
    this.requirements,
    this.goals,
    this.rules,
    this.isVariable,
  });

  @override
  Widget build(BuildContext context) {
    return OfferDetailScreen(
      offerId: offerId,
      provider: provider,
      title: title,
      coins: coins,
      description: description,
      duration: duration,
      requirements: requirements,
      goals: goals,
      rules: rules,
      isVariable: isVariable,
    );
  }
}

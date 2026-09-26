import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Missions are intentionally not rendered until the backend exposes a
/// missions endpoint. Progress and rewards must never be inferred locally.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Icon(Icons.track_changes_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('Daily Missions',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.track_changes_rounded,
                            size: 46, color: AppColors.textTertiary),
                        SizedBox(height: 14),
                        Text('Missions are not available yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 8),
                        Text(
                          'Mission progress and rewards will appear here when the server provides them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

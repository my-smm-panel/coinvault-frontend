import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/provider_logos.dart';
import '../services/app_repository.dart';
import '../widgets/app_logo.dart';

/// Detail page for one backend offer. Optional fields are shown only when the
/// offer payload supplied them; this screen does not estimate or invent data.
class TaskDetailScreen extends StatefulWidget {
  final String provider;
  final String title;
  final String desc;
  final int? coins;
  final List<String>? steps;
  final String? offerId;

  const TaskDetailScreen({
    super.key,
    required this.provider,
    required this.title,
    required this.desc,
    this.coins,
    this.steps,
    this.offerId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _started = false;
  bool _starting = false;

  String? get _validOfferId {
    final id = widget.offerId?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  Future<void> _startTask() async {
    final id = _validOfferId;
    if (id == null || _starting || _started) {
      if (id == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This task has no valid backend offer ID')),
        );
      }
      return;
    }

    setState(() => _starting = true);
    try {
      final result = await AppRepository.instance.startOffer(id);
      if (!mounted) return;
      setState(() {
        _starting = false;
        _started = true;
      });

      final rawUrl = (result['trackingUrl'] ??
              result['clickUrl'] ??
              result['externalUrl'] ??
              result['redirectUrl'] ??
              result['url'] ??
              '')
          .toString()
          .trim();
      final uri = Uri.tryParse(rawUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task started; no tracking link was provided')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start this task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = ProviderLogos.colorFor(widget.provider);
    final steps = widget.steps ?? const <String>[];
    final hasId = _validOfferId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _header(color),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title.trim().isNotEmpty) ...[
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w800),
                      ),
                      if (widget.desc.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.desc,
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ] else if (widget.desc.trim().isNotEmpty) ...[
                      Text(
                        widget.desc,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (steps.isNotEmpty) _stepsCard(color, steps),
                  ],
                ),
              ),
            ),
            _bottomCta(color, hasId),
          ],
        ),
      ),
    );
  }

  Widget _header(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppColors.brandHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppLogo(
              provider: widget.provider,
              title: widget.title,
              size: 44,
              radius: 10,
              fallbackIcon: Icons.task_alt_rounded,
              fallbackColor: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.provider,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard(Color color, List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text('Instructions',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(e.value,
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _bottomCta(Color color, bool hasId) {
    final enabled = hasId && !_started && !_starting;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border(
            top: BorderSide(color: AppColors.textPrimary.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: enabled ? _startTask : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? color : const Color(0xFFE8F0FF),
                foregroundColor: enabled ? Colors.white : AppColors.textSecondary,
                disabledBackgroundColor: const Color(0xFFE8F0FF),
                disabledForegroundColor: AppColors.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _started
                        ? Icons.check_circle_outline_rounded
                        : _starting
                            ? Icons.hourglass_top_rounded
                            : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _started
                        ? 'In Progress'
                        : _starting
                            ? 'Starting…'
                            : hasId
                                ? 'Start Task'
                                : 'Start unavailable',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          if (!hasId)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('This task has no valid backend offer ID.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
